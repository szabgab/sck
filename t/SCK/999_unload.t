#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use Redis;
my $r = Redis->new( server => "127.0.0.1:16379" );
if ( is( $r->ping, "PONG", "Check connexion" ) ) {
    is( $r->flushall(), "OK", "Flushall" );
    is( $r->shutdown(), "1",  "Shutdown" );
}

