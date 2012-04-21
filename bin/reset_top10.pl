#!/usr/bin/env perl 

# PODNAME: reset_top10
# ABSTRACT: Reinitialize the top 10 and min_letters

use strict;
use warnings;
use 5.014;
# VERSION
use Carp;

use Dancer ':script';
use Celogeek::SCK::Store;

my $store = Celogeek::SCK::Store->new_with_config(config->{store});
$store->reset_top10;
