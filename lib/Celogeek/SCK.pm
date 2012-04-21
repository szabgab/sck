package Celogeek::SCK;

# ABSTRACT: Celogeek::SCK Core - a service to shorten your URL

=head1 SYNOPSIS

    use Celogeek::SCK;

    my $sck = Celogeek::SCK->new(store => Celogeek::SCK::Store->new(...), max_generated_times => 5, max_letters => 10);
    my $short_url = $sck->shorten('http://www.montest.com');
    my $long_url = $sck->enlarge($short_url);

=cut

use strict;
use warnings;
use 5.014;

# VERSION

use Moo;

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

use Regexp::Common qw /number/;

has 'store' => (
    'is'       => 'rw',
    'isa'      => sub {
        die "$_[0] is not a Celogeek::SCK::Store object" unless $_[0]->isa('Celogeek::SCK::Store');
    },
    'required' => 1,
);

has 'generated_times' => (
    'is'      => 'rw',
    'isa'     => sub {
        die "$_[0] is not a number" unless $_[0] =~ /^$RE{num}{int}$/;
    },
    'default' => sub {0},
);

has 'max_generated_times' => (
    'is'      => 'rw',
    'isa'     => sub {
        die "$_[0] is not a number" unless $_[0] =~ /^$RE{num}{int}$/;
    },
    'default' => sub {0},
);

has 'max_letters' => (
    'is'      => 'rw',
    'isa'     => sub {
        die "$_[0] is not a number" unless $_[0] =~ /^$RE{num}{int}$/;
    },
    'default' => sub {1},
);

has 'min_letters' => (
    'is' => 'rw',
    'default' => sub {1},
);

has 'status' => (
    'is'  => 'rw',
);

has 'check_method' => (
    'is'      => 'rw',
    'default' => sub {'header'},
);

=method generate

Generate a short link. It will start with min_letters, and try to find a random short link smaller than max_metter.
If a range of letter is not found, it add 1 letter to min_letters and try again.

It throw "SCK:[NO WAY TO SHORTEN]" if the generator couldn't find anything

=cut

sub generate {
    my ($self) = @_;

    croak 'SCK:[NO WAY TO SHORTEN]' if $self->max_letters < $self->min_letters;

    my @letters_to_use = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9, '/' );

    while ( $self->max_generated_times > $self->generated_times ) {

        #get random data to build a key with the size of min_letters
        my $shorturl = rand_data_string( $self->min_letters, \@letters_to_use );

        #cleanup (remove double /, / on start and at the end)
        $shorturl =~ s!/+!/!xg;
        $shorturl =~ s!/$!!x;
        $shorturl =~ s!^/!!x;
        next if $shorturl eq '';    #one letter, only a /

        $self->generated_times( $self->generated_times + 1 );

        #we got a new key !
        unless ( $self->store->exists_by_shorturl( $shorturl ) ) {
            return $shorturl;
        }
    }

    #try again with a min_letters + 1
    $self->max_generated_times(
        $self->max_generated_times + $self->generated_times );
    $self->min_letters($self->min_letters + 1);
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

    #check if we have already shortenize the url
    if ( $self->store->exists_by_url($url) ) {
        return $self->store->get_by_url($url, 'path' );
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
        my $now = _datetime_str(DateTime->now);
        $self->store->set_by_url($url,
            path             => $short,
            clicks           => 0,
            clicks_uniq      => 0,
            created_at       => $now,
            last_accessed_at => $now,
        );
        return $short;
    }
}

=method enlarge

Try to get the long url from a key

=cut

sub enlarge {
    my ( $self, $shorturl, %opts ) = @_;
    my $clicks      = $opts{clicks}      // 0;
    my $clicks_uniq = $opts{clicks_uniq} // 0;
    croak 'SCK:[THIS KEY DOESNT EXIST]'
    unless $self->store->exists_by_shorturl($shorturl);

    #we have a clicks
    if ($clicks) {
        my $today = DateTime->now; 

        #incr click part
        $self->store->increment_by_shorturl($shorturl, 'clicks', 1);
        $self->store->increment_stat('traffic', $today->ymd, 1);

        #we have a clicks_uniq
        if ($clicks_uniq) {

            #add score to element
            $self->store->increment_by_shorturl($shorturl, 'clicks_uniq', 1);

            #add a score to top10
            $self->store->increment_top10_by_shorturl($shorturl, 1);

            #add a score to traffic

            $self->store->increment_stat('traffic:uniq', $today->ymd, 1);
        }
        $self->store->set_by_shorturl( $shorturl, last_accessed_at => _datetime_str($today) );
    }
    return $self->store->url_from_shorturl($shorturl);
}

=method stats

Return stats for a specific key

=cut

sub stats {
    my ( $self, $shorturl, %opts ) = @_;
    $opts{date_format} //= '%c UTC';

    if ( $self->store->exists_by_shorturl( $shorturl ) ) {
        my %data = $self->store->get_by_shorturl($shorturl);
        foreach my $d (qw/created_at last_accessed_at/) {
            if ( $data{$d} ) {
                $data{$d} = _datetime( $data{$d} )
                    ->strftime( $opts{date_format} );
            }
        }
        return \%data;
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
    $self->store->get_by_url($url, 'title');
}

=method top10

Return the top10 of most clicks links of the week. Only one click per day per user add a score

=cut

sub top10 {
    my ($self) = @_;

    my @top10 = $self->store->top10(title => qr/^[a-zA-Z0-9\.\s\'\"\(\)\r\n\[\]\{\}\|\-\,\;\&\:\!\?\/\#\@\<\>\+\*\™\’\»\_\$\£\=]+$/);
    return \@top10;
}

#return a formated DateTime from DateTime or String
sub _datetime {
    my ( $date ) = @_;
    if ( ref $date && $date->isa('DateTime') ) {
        return $date;
    }
    else {
        return DateTime::Format::DateParse->parse_datetime( $date, 'UTC' );
    }
}

#return a str of DateTime
sub _datetime_str {
    my ($date) = @_;

    return $date->ymd . ' ' . $date->hms;
}

1;
