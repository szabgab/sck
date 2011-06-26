#!/usr/bin/env perl 

# PODNAME: Cleaner
# ABSTRACT: clean all bad link

use strict;
use warnings;
use 5.014;
use Carp;

use Dancer ':script';
use Dancer::Plugin::Redis;
use Celogeek::SCK::Cleaner;

my $cleaner = Celogeek::SCK::Cleaner->new_with_options();

my $redis = redis;

foreach my $key ( $redis->keys("h:*") ) {
    my ( $url, $status ) = $redis->hmget( $key, 'url', 'status' );

    #check if it's an SCK key
    unless ( $cleaner->is_valid_uri( uri => $url ) ) {
        say "Bad link : $url";
        $redis->del($key) if $cleaner->run();
        next;
    }

    if ( defined $status && $status ne '200 OK' ) {
        say "Bad status link : $url ($status)";
        $redis->del($key) if $cleaner->run();
        next;
    }

}

foreach my $pkey ( $redis->keys("p:*") ) {
    my $key = $redis->get($pkey);
    unless ( $redis->exists($key) ) {
        say "Removing $pkey";
        $redis->del($pkey) if $cleaner->run();
        say "Removing top10 member $key";
        $redis->zrem( 's:top10', $key );
    }
}

say "Removing is not effective, add --run to do it really"
    unless $cleaner->run();
