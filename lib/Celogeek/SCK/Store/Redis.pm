package Celogeek::SCK::Store::Redis;

# ABSTRACT: Redis store engine

use strict;
use warnings;
use Carp;
# VERSION
use 5.012;

use Digest::SHA1 qw/sha1_hex/;

use Moo::Role;

=method validate_connection

Check if connection is a Redis connection

=cut
sub validate_connection {
    my $self = shift;
    croak "not a Redis connection" unless ref $self->connection && $self->connection->isa('Redis');
}

=method get_by_url

Get information using URL as a key

=cut
sub get_by_url {
    my $self = shift;
    my ($url, $key) = @_;
    if (defined $key) {
        return $self->connection->hget('h:'.sha1_hex($url), $key),
    } else {
        return $self->connection->hgetall('h:'.sha1_hex($url)),
    }
}

=method set_by_url

Set information using URL as a key

=cut
sub set_by_url {
    my $self = shift;
    my ($url, %info) = @_;


    if (defined $info{path}) {
        #keep index
        $self->connection->set('p:'.sha1_hex($info{path}), 'h:'.sha1_hex($url));
        #add url to info
        $info{url} = $url;
    }
    $self->connection->hmset('h:'.sha1_hex($url), %info);

    return;
}

=method exists_by_url

Check if url is already stored

=cut
sub exists_by_url {
    my $self = shift;
    my ($url) = @_;

    $self->connection->exists('h:'.sha1_hex($url));
}

=method increment_by_url

Increment a counter by url

=cut
sub increment_by_url {
    my $self = shift;
    my ($url, $counter, $number) = @_;

    $self->connection->hincrby('h:'.sha1_hex($url), $counter, $number // 1);
}


=method get_by_shorturl

Get information using the short key

=cut
sub get_by_shorturl {
    my $self = shift;
    my ($shorturl, $key) = @_;

    $self->get_by_url($self->url_from_shorturl($shorturl), $key);
}

=method set_by_shorturl

Set information using the short key

=cut
sub set_by_shorturl {
    my $self = shift;
    my ($shorturl, %info) = @_;

    $self->set_by_url($self->url_from_shorturl($shorturl), %info);
}

=method exists_by_shorturl

Check if shorturl is already stored

=cut
sub exists_by_shorturl {
    my $self = shift;
    my ($shorturl) = @_;

    $self->connection->exists('p:'.sha1_hex($shorturl));
}

=method increment_by_shorturl

Increment a counter by shorturl

=cut
sub increment_by_shorturl {
    my $self = shift;
    my ($shorturl, $counter, $number) = @_;

    $self->increment_by_url($self->url_from_shorturl($shorturl), $counter, $number);
}

=method increment_top10_by_url

Add score to a url by its url

=cut
sub increment_top10_by_url {
    my $self = shift;
    my ($url, $number) = @_;
    $self->connection->zincrby( 's:top10', $number // 1, 'h:'.sha1_hex($url) );
}

=method increment_stat

Increment stat counter

=cut
sub increment_stat {
    my $self = shift;
    my ($stat, $key, $val) = @_;
    $self->connection->hincrby('s:'.$stat, $key, $val // 1);
}

=method increment_top10_by_shorturl

Add score to a url by its shorturl

=cut
sub increment_top10_by_shorturl {
    my $self = shift;
    my ($shorturl, $number) = @_;
    $self->increment_top10_by_url($self->url_from_shorturl($shorturl), $number);
}

=method url_from_shorturl

Return url from shorturl

=cut
sub url_from_shorturl {
    my $self = shift;
    my ($shorturl) = @_;

    my $h_url = $self->connection->get('p:'.sha1_hex($shorturl));
    $self->connection->hget($h_url, 'url');
}

=method top10

Return top10 using filter

=cut
sub top10 {
    my $self = shift;
    my (%filters) = @_;

    my @members_with_score
        = $self->connection->zrevrange( 's:top10', 0, -1, 'WITHSCORES' );
        
    my @top10_data = ();

    MEMBER:
    for ( my $i = 0; $i < @members_with_score; $i += 2 ) {
        my ( $member_key, $member_score ) = @members_with_score[ $i .. $i + 1 ];

        my $url = $self->connection->hget($member_key, 'url');
        my %data = $self->get_by_url($url);
        for my $key(keys %filters) {
            my $filter = $filters{$key};
            unless(defined $data{$key} && $data{$key} =~ $filter) {
                next MEMBER;
            }
        }
        $data{score} = $member_score;

        $data{alt} = '';
        if ( $data{title} ) {
            Encode::_utf8_on( $data{title} );

            #if title exist, use it
            if ( $data{title} ne $data{url} ) {
                $data{alt} = $data{title} . ' - ';
            }
        }
        else {
            $data{title} = $data{url};
        }

        #set alt
        $data{alt} .= $data{url} . ' - Score ' . $data{score};

        push @top10_data, \%data;
        last MEMBER unless @top10_data < 10; 
    }
    return @top10_data;
}

1;
