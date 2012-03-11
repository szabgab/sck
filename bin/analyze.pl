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

my $redis = redis;

foreach my $key ( $redis->keys("h:*") ) {
    my %info = $redis->hgetall($key);
    unless ( $ENV{FORCE} ) {
        if ( $ENV{FORCE_ONLY_BAD_STATUS} ) {
            if ( ( $info{status} // '' ) eq '200 OK' ) {
                next;
            }
        }
        else {
            if ( defined $info{analyzer}
                && $info{analyzer} ==
                $Celogeek::SCK::Analyzer::ANALYZER_VERSION )
            {
                next;
            }
        }
    }

    #get real uri
    my ($url) = $info{url};
    my ($path) = $info{path};

    say "";
    say "Analyzing $key";
    say "   URL : ", $url;
    say " Short : http://sck.to/", $path;
    say " Stats : http://sck.to/", $path,"?s=1";

    my $analyzer =
      Celogeek::SCK::Analyzer->new( uri => $url, method => 'full' );

    #check if status is 200 (only reachable link is ok)
    my $header = $analyzer->header();
    next unless $header;
    say "   Status : ",       $header->{status};
    say "   Content-Type : ", $header->{content_type};
    say "   Encoding : ",     $header->{encoding};
    foreach my $header_key (qw(status content_type encoding)) {
        $redis->hset( $key, $header_key, $header->{$header_key} );
    }

    #set analyzer version if status OK
    $redis->hset( $key, 'analyzer',
        $Celogeek::SCK::Analyzer::ANALYZER_VERSION );

    my $content = $analyzer->content();
    next unless $content;
    say "   Title : ",         $content->{title};
    say "   Short Content : ", $content->{short_content};
    $redis->hset( $key, 'title',         $content->{title} );
    $redis->hset( $key, 'short_content', $content->{short_content} );

}

