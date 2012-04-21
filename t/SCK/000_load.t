#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    require_ok('Celogeek::SCK') || print "Bail out!
";
}

diag("Testing Test $Celogeek::SCK::VERSION, Perl $], $^X");

use Dancer::Test;
Dancer::set environment => 'testing';
Dancer::Config->load;
require 't/SCK/engine/'.Dancer::config->{store}->{engine}.'_load.ttt';

done_testing;
