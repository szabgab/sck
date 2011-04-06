#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use t::SCK::TestSCK;
route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
