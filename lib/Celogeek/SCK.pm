package Celogeek::SCK;

# ABSTRACT: Celogeek::SCK Core - a service to shorten your URL

=head1 SYNOPSIS

    use Celogeek::SCK;

    my $sck = Celogeek::SCK->new(redis => redis, max_generated_times => 5, max_letters => 10);
    my $short_url = $sck->shorten('http://www.montest.com');
    my $long_url = $sck->enlarge($short_url);

=cut

use strict;
use warnings;
use 5.014;

# VERSION

use Moose;

use Celogeek::SCK::Cleaner;
my $_cleaner = Celogeek::SCK::Cleaner->new();
use Celogeek::SCK::Analyzer;

use Data::Rand qw/rand_data_string/;
use Digest::SHA1 qw/sha1_hex/;
use File::Basename;
use File::Path;
use File::Spec;
use Carp;
use DateTime;
use DateTime::Format::DateParse;
use Try::Tiny;
use Encode;

has 'redis' => (
    'is'       => 'rw',
    'isa'      => 'Redis',
    'required' => 1,
);

has 'generated_times' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => 0,
);

has 'max_generated_times' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => 0,
);

has 'max_letters' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => 1,
);

has 'status' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

has 'check_method' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => 'header',
);

=method BUILD

Initialize the SCK core.

=cut

sub BUILD {
    my ($self) = @_;
    $self->redis->incr('c:min_letters')
        unless $self->redis->exists('c:min_letters');
    return;
}

=method generate

Generate a short link. It will start with min_letters, and try to find a random short link smaller than max_metter.
If a range of letter is not found, it add 1 letter to min_letters and try again.

It throw "SCK:[NO WAY TO SHORTEN]" if the generator couldn't find anything

=cut

sub generate {
    my ($self) = @_;

    my $key_size = $self->redis->get('c:min_letters');
    croak 'SCK:[NO WAY TO SHORTEN]' if $self->max_letters < $key_size;

    my @letters_to_use = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, '/' );

    while ( $self->max_generated_times > $self->generated_times ) {

        #get random data to build a key with the size of key_size
        my $key = rand_data_string( $key_size, \@letters_to_use );

        #cleanup (remove double /, / on start and at the end)
        $key =~ s!/+!/!xg;
        $key =~ s!/$!!x;
        $key =~ s!^/!!x;
        next if $key eq '';    #one letter, only a /

        $self->generated_times( $self->generated_times + 1 );

        #we got a new key !
        unless ( $self->redis->exists( $self->_path_key($key) ) ) {
            return $key;
        }
    }

    #try again with a min_letters + 1
    $self->max_generated_times(
        $self->max_generated_times + $self->generated_times );
    $self->redis->incr('c:min_letters');
    return $self->generate();
}

=method shorten

Return an existing short key for long url, or try to generate a new one

=cut

sub shorten {
    my ( $self, $url ) = @_;
    try {
        croak 'SCK:[BAD URL]' unless $_cleaner->is_valid_uri( uri => $url );
    }
    catch {
        croak 'SCK:[BAD URL]';
    };

    #look in redis db
    my $hash_key = $self->_hash_key($url);
    if ( $self->redis->exists($hash_key) ) {
        return $self->redis->hget( $hash_key, 'path' );
    }
    else {

        #check url
        my $analyzer = Celogeek::SCK::Analyzer->new(
            uri    => $url,
            method => $self->check_method()
        );
        my $header = $analyzer->header();
        $self->status( $header->{status} );

        #porn link
        if ( $self->status() eq 'PORN/ILLEGAL' ) {
            croak 'SCK:[PORN/ILLEGAL]';
        }

        #status is not 200 OK, unreachable
        if ( $self->status() ne '200 OK' ) {
            croak 'SCK:[UNREACHABLE HOST]';
        }

        #generate a new one
        $self->generated_times(0);
        my $short = $self->generate();
        $self->_save(
            $hash_key,
            {   url              => $url,
                path             => $short,
                clicks           => 0,
                clicks_uniq      => 0,
                created_at       => DateTime->now,
                last_accessed_at => DateTime->now
            }
        );
        $self->redis->set( $self->_path_key($short), $hash_key );
        return $short;
    }
}

=method enlarge

Try to get the long url from a key

=cut

sub enlarge {
    my ( $self, $key, %opts ) = @_;
    my $clicks      = $opts{clicks}      // 0;
    my $clicks_uniq = $opts{clicks_uniq} // 0;
    croak 'SCK:[THIS KEY DOESNT EXIST]'
        unless ( $self->redis->exists( $self->_path_key($key) ) );

    my $hash_key = $self->redis->get( $self->_path_key($key) );

    #we have a clicks
    if ($clicks) {
        my $today = DateTime->now; 

        #incr click part
        $self->redis->hincrby( $hash_key, 'clicks', 1 );
        $self->redis->hincrby( 's:traffic', $today->ymd, 1 );

        #we have a clicks_uniq
        if ($clicks_uniq) {

            #add score to element
            $self->redis->hincrby( $hash_key, 'clicks_uniq', 1 );

            #add a score to top10
            $self->redis->zincrby( 's:top10', 1, $hash_key );

            #add a score to traffic

            $self->redis->hincrby( 's:traffic:uniq', $today->ymd, 1 );
        }
        $self->_save( $hash_key, { last_accessed_at => $today } );
    }
    return $self->redis->hget( $hash_key, 'url' );
}

=method stats

Return stats for a specific key

=cut

sub stats {
    my ( $self, $key, %opts ) = @_;
    $opts{date_format} //= '%c UTC';

    if ( $self->redis->exists( $self->_path_key($key) ) ) {
        my $data = $self->_get( $self->redis->get( $self->_path_key($key) ) );
        foreach my $d (qw/created_at last_accessed_at/) {
            if ( $data->{$d} ) {
                $data->{$d} = $self->_datetime( $data->{$d} )
                    ->strftime( $opts{date_format} );
            }
        }
        return $data;
    }
    else {
        croak 'SCK:[THIS KEY DOESNT EXIST]';
    }
}

=method title

Return the title fetch from url

=cut

sub title {
    my ($self, $url) = @_;
    my $title;
    if ( $self->redis->exists( $self->_hash_key($url) ) ) {
        $title = $self->redis->hget($self->_hash_key($url), "title");
    }
    return $title;
}

=method top10

Return the top10 of most clicks links of the week. Only one click per day per user add a score

=cut

sub top10 {
    my ($self) = @_;

    my @members_with_score
        = $self->redis->zrevrange( 's:top10', 0, 9, 'WITHSCORES' );
    my @top10_data = ();

    for ( my $i = 0; $i < @members_with_score; $i += 2 ) {
        my ( $member_key, $member_score )
            = @members_with_score[ $i .. $i + 1 ];

        #fetch data
        my $data = { score => $member_score };
        $data->{$_} = $self->redis->hget( $member_key, $_ )
            for qw/url path title/;

        $data->{alt} = '';

        # too many try, never try again
        if ( $data->{title} ) {
            Encode::_utf8_on( $data->{title} );

            #if title exist, use it
            if ( $data->{title} ne $data->{url} ) {
                $data->{alt} = $data->{title} . ' - ';
            }
        }
        else {
            $data->{title} = $data->{url};
        }

        #set alt
        $data->{alt} .= $data->{url} . ' - Score ' . $data->{score};

        push @top10_data, $data;
    }
    return \@top10_data;
}

#return a formated DateTime from DateTime or String
sub _datetime {
    my ( $self, $date ) = @_;
    if ( ref $date && $date->isa('DateTime') ) {
        return $date;
    }
    else {
        return DateTime::Format::DateParse->parse_datetime( $date, 'UTC' );
    }
}

#return a str of DateTime
sub _datetime_str {
    my $self = shift;
    my $date = shift;

    return $date->ymd . ' ' . $date->hms;
}

#save a hash to redis
sub _save {
    my $self     = shift;
    my $hash_key = shift;
    my $data     = shift;

    foreach my $key ( keys %$data ) {
        my $val = $data->{$key};
        if ( ref $val eq 'DateTime' ) {
            $data->{$key} = $self->_datetime_str($val);
        }
    }
    $self->redis->hmset( $hash_key, %$data );

    return;
}

#get an hash from redis
sub _get {
    my $self     = shift;
    my $hash_key = shift;
    my %data
        = $self->redis->exists($hash_key)
        ? $self->redis->hgetall($hash_key)
        : ();
    return \%data;
}

#common part of redis key
sub _redis_key {
    my $self   = shift;
    my $prefix = shift;
    my $key    = shift;
    return $prefix . ':' . sha1_hex($key);
}

#key for path (short link), start with p:
sub _path_key {
    my $self = shift;
    my $path = shift;
    return $self->_redis_key( 'p', $path );
}

#key for hash (url information), start with h:
sub _hash_key {
    my $self = shift;
    my $url  = shift;
    return $self->_redis_key( 'h', $url );
}

no Moose;
__PACKAGE__->meta->make_immutable();
1;
