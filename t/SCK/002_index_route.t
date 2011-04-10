#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use t::SCK::TestSCK;

{
    note "Test root";
    route_exists [ GET => '/' ], 'a route handler is defined for /';
    response_status_is [ 'GET' => '/' ], 200, 'response status is 200 for /';
}
