#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok( 'Celogeek::SCK' ) || print "Bail out!
";
}

diag( "Testing Test $Celogeek::URL::VERSION, Perl $], $^X" );

note ("Starting Redis Test");
system ("redis-server ./t/db/redis.conf && sleep 1");
use Redis;
my $r = Redis->new(server => "127.0.0.1:16379");
if (is ($r->ping, "PONG", "Check connexion")) {
    is ($r->flushall(),"OK", "Flushall");
}

