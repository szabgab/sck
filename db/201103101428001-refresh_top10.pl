#!/usr/bin/perl 
use strict;
use warnings;
use Redis;

my $r = Redis->new( server => "localhost:6701" );

{
    my @hk = $r->keys("h:*");
    foreach my $key (@hk) {
        my $rank = $r->hget( $key, "clicks_uniq" );
        printf "%42s - %4d\n", $key, $rank;
        $r->zadd( "s:top10", $rank, $key ) if $rank > 0;
    }
}

