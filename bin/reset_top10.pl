#!/usr/bin/env perl 

# PODNAME: reset_top10
# ABSTRACT: Reinitialize the top 10 and min_letters

use strict;
use warnings;
use 5.014;
use Carp;

use Dancer ':script';
use Dancer::Plugin::Redis;
use Celogeek::SCK::Analyzer;

my $redis = redis;

$redis->del("s:top10");
$redis->set("c:min_letters", 1);

