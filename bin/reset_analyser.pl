#!/usr/bin/env perl 

# PODNAME: Analyze
# ABSTRACT: analyze all url and extract usefull content

use strict;
use warnings;
use 5.014;
# VERSION
use Carp;

use Dancer ':script';
use Celogeek::SCK::Store;

{
	package cmd;
	use Moo;
	use MooX::Options;
	option filter => (is => 'ro', format => "s", doc => 'filter regex for url');
	option run => (is => 'ro', doc => 'run the clearer', default => 0);
	1;
}

my $cmd = cmd->new_with_options;
my $store = Celogeek::SCK::Store->new_with_config(config->{store});
my %urls_info = $store->all_by_url;

my $prefix = $cmd->run ? "Clear" : "Will clear";
while( my ($url, $info) = each %urls_info ) {

    next if defined $cmd->filter && $url !~ $cmd->filter;

	say "$prefix $url";
    $store->set_by_url($url,
        analyzer => undef,
        status => 403,
    ) if $cmd->run;

}

