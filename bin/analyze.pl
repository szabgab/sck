#!/usr/bin/env perl 

# PODNAME: Analyze
# ABSTRACT: analyze all url and extract usefull content

use strict;
use warnings;
use 5.012;
use Carp;

use Dancer ':syntax';
use Dancer::Plugin::Redis;
use Celogeek::SCK::Analyzer;

foreach my $key(redis->keys("h:*")) {
    say "";
    say "Analyzing $key";

    #get real uri
    my ($url) = redis->hget($key, "url");
    say "   URL : ",$url;
    
    my $analyzer = Celogeek::SCK::Analyzer->new(uri => $url, method => 'full');

    #check if it's an SCK key
    unless ($analyzer->is_valid_uri()) {
        say "   SCK URI, REMOVING : $url";
        redis->del($key);
        next;
    }

    #check if status is 200 (only reachable link is ok)
    my $header = $analyzer->header();
    say "   Status : ",$header->{status};
    say "   Content-Type : ",$header->{content_type};
    say "   Encoding : ",$header->{encoding};

    my $content = $analyzer->content();
    say "   Title : ", $content->{title};

};

say "";
say "====";
say "";
say "Cleaning pkey";
foreach my $pkey(redis->keys("p:*")) {
    my $key = redis->get($pkey);
    unless (redis->exists($key)) {
        say "    Removing $pkey";
        redis->del($pkey);
    }
}
say "Done";
