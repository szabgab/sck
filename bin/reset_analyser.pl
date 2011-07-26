#!/usr/bin/env perl 

# PODNAME: Analyze
# ABSTRACT: analyze all url and extract usefull content

use strict;
use warnings;
use 5.014;
use Carp;

use Dancer ':script';
use Dancer::Plugin::Redis 0.3;
use Celogeek::SCK::Analyzer;

my $redis = redis;

foreach my $key ( $redis->keys("h:*") ) {
	$redis->hdel($key, 'analyzer');
}

