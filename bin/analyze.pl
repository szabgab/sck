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
use JSON ();

foreach my $key(redis->keys("h:*")) {
    my ($analyzer_version) = redis->hget($key, "analyzer");
    next if defined $analyzer_version && $analyzer_version == $Celogeek::SCK::Analyzer::ANALYZER_VERSION;

    #get real uri
    my ($url) = redis->hget($key, "url");
    
    say "";
    say "Analyzing $key";
    say "   URL : ",$url;

    my $analyzer = Celogeek::SCK::Analyzer->new(uri => $url, method => 'full');

   #check if status is 200 (only reachable link is ok)
    my $header = $analyzer->header();
    next unless $header;
    say "   Status : ",$header->{status};
    say "   Content-Type : ",$header->{content_type};
    say "   Encoding : ",$header->{encoding};
    foreach my $header_key(qw(status content_type encoding)) {
        redis->hset($key, $header_key, $header->{$header_key});
    }

    #set analyzer version if status OK
    if ($header->{status} eq '200 OK' || $header->{status} eq 'PORN/ILLEGAL') {
        redis->hset($key, 'analyzer', $Celogeek::SCK::Analyzer::ANALYZER_VERSION);
    }

    my $content = $analyzer->content();
    next unless $content;
    say "   Title : ", $content->{title};
    redis->hset($key, 'title', $content->{title});
    redis->hset($key, 'word_score', JSON::encode_json($content->{word_score}));

};

say "";
say "Done";
