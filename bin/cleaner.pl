#!/usr/bin/env perl 

# PODNAME: Cleaner
# ABSTRACT: clean all bad link

use strict;
use warnings;
use 5.014;
# VERSION
use Carp;

use Dancer ':script';
use Celogeek::SCK::Cleaner;
use Celogeek::SCK::Store;

my $cleaner = Celogeek::SCK::Cleaner->new_with_options();

my $store = Celogeek::SCK::Store->new_with_config(config->{store});
my %urls_info = $store->all_by_url;

while( my ($url, $info) = each %urls_info ) {
    my $status = $info->{status};
    my $content_type = $info->{content_type};

    #check if it's an SCK key
    unless ( $cleaner->is_valid_uri( uri => $url ) ) {
        say "Bad link : $url";
        $store->del_by_url($url) if $cleaner->run();
        next;
    }

    if ( defined $status && $status ne '200 OK' ) {
        say "Bad status link : $url ($status)";
        $store->del_by_url($url) if $cleaner->run();
        next;
    }

    if ( defined $content_type && $content_type !~ /text|xml|html|image/) {
        say "Bad content type : $url ($content_type)";
        $store->del_by_url($url) if $cleaner->run();
        next;
    }

}

say "Removing is not effective, add --run to do it really"
    unless $cleaner->run();
