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
use Celogeek::SCK::Analyzer;

my $store = Celogeek::SCK::Store->new_with_config(config->{store});
my %urls_info = $store->all_by_url;

while( my ($url, $info) = each %urls_info ) {
    unless ( $ENV{FORCE} ) {
        if ( $ENV{FORCE_ONLY_BAD_STATUS} ) {
            if ( ( $info->{status} // '' ) eq '200 OK' ) {
                next;
            }
        }
        else {
            if ( defined $info->{analyzer}
                && $info->{analyzer} ==
                $Celogeek::SCK::Analyzer::ANALYZER_VERSION )
            {
                next;
            }
        }
    }

    say "";
    say "Analyzing <$url>";
    say " Short : http://sck.to/", $info->{path};
    say " Stats : http://sck.to/", $info->{path},"?s=1";

    my $analyzer =
      Celogeek::SCK::Analyzer->new( uri => $url, method => 'full' );

    #check if status is 200 (only reachable link is ok)
    my $header = $analyzer->header();
    next unless $header;
    say "   Status : ",       $header->{status};
    say "   Content-Type : ", $header->{content_type};
    say "   Encoding : ",     $header->{encoding};

    $store->set_by_url($url, 
        status => $header->{status},
        content_type => $header->{content_type},
        encoding => $header->{encoding},
        analyzer => $Celogeek::SCK::Analyzer::ANALYZER_VERSION,
    );

    my $content = $analyzer->content();
    next unless $content;
    say "   Title : ",         $content->{title};
    say "   Short Content : ", $content->{short_content};
    
    $store->set_by_url($url,
        title => $content->{title},
        short_content => $content->{short_content},
    );

}

