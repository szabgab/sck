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
    my ($analyzer_version) = $redis->hget( $key, "analyzer" );
    unless ( $ENV{FORCE} ) {
        if ( $ENV{FORCE_ONLY_BAD_STATUS} ) {
            if ( ( $redis->hget( $key, 'status' ) // '' ) eq '200 OK' ) {
                next;
            }
        }
        else {
            if ( defined $analyzer_version
                && $analyzer_version ==
                $Celogeek::SCK::Analyzer::ANALYZER_VERSION )
            {
                next;
            }
        }
    }

    #get real uri
    my ($url) = $redis->hget( $key, "url" );

    say "";
    say "Analyzing $key";
    say "   URL : ", $url;

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

