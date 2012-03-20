#!/usr/bin/env perl 

# PODNAME: Analyze
# ABSTRACT: analyze all url and extract usefull content

use strict;
use warnings;
use 5.014;
# VERSION
use Carp;

use Dancer ':script';
use Dancer::Plugin::Redis 0.03;
use Celogeek::SCK::Analyzer;

{
	package cmd;
	use Moo;
	use MooX::Options;
	option filter => (is => 'ro', format => "s", doc => 'filter regex for url');
	option run => (is => 'ro', doc => 'run the clearer', default => 0);
	1;
}

my $cmd = cmd->new_with_options;
my $redis = redis;

my $prefix = $cmd->run ? "Clear" : "Will clear";
foreach my $key ( $redis->keys("h:*") ) {
	my $url = $redis->hget($key, 'url');

	defined $cmd->filter and 
	($url =~ $cmd->filter or next);

	say "$prefix $url";
	$cmd->run and $redis->hdel( $key, 'analyzer' ) and $redis->hset($key, 'status', '403');
}

