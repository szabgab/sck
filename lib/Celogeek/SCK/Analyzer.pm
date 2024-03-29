package Celogeek::SCK::Analyzer;

# ABSTRACT: Celogeek::SCK::Analyzer - Analyze content of title and populate database

use strict;
use warnings;
use 5.014;

# VERSION

use Data::Dumper;
use Carp;

use Moo;

use LWP::UserAgent;
use Encode;
use HTML::Entities qw(decode_entities);
use HTML::ContentExtractor;

use Regexp::Common qw(whitespace);
use Config::YAML;

use Net::DNS;

use URI;

#set analyzer version, permit to rescan only old or new link
$Celogeek::SCK::Analyzer::ANALYZER_VERSION = 2;

#check dns
my $_local_resolver = Net::DNS::Resolver->new;
$_local_resolver->nameservers('127.0.0.1');

#set opendns server
my $_resolver        = Net::DNS::Resolver->new;
$_resolver->nameservers( '208.67.222.222', '208.67.220.220' );

#bad ip
my $_resolver_bad_ip = '67.215.65.130';


#init UA

#agent
my $_agent = "PerlBot_SCK/";
$_agent .= $Celogeek::SCK::Analyzer::VERSION // "DEV";

#extract header
my $_ua_header = LWP::UserAgent->new;
$_ua_header->agent($_agent);
$_ua_header->timeout(10);
$_ua_header->max_size(2000);

#extract content
my $_ua_content = LWP::UserAgent->new;
$_ua_content->agent($_agent);
$_ua_content->timeout(30);

=attr uri

URI to analyze

=cut

has uri => (
    is       => 'rw',
    required => 1,
    trigger => sub {
        my ($self, $uri) = @_;
        $self->uri(URI->new($uri)) unless ref $uri and $uri->isa('URI');
    },
);

=attr header

Content all useful headers of uri

=cut

has header => (
    is      => 'rw',
    default => sub { {} },
    isa => sub {
        die "$_[0] is not a hash ref" unless ref $_[0] eq 'HASH'; 
    },
);

=attr content

Content for url

=cut

has content => (
    is  => 'rw',
    isa => sub {
        die "$_[0] is not a hash ref" unless ref $_[0] eq 'HASH'; 
    },
);

=attr method

Method of extraction

    host: check only host for api
    header: extract header only
    full: get title, short content

=cut

has method => (
    is       => 'rw',
    required => 1,
    default  => sub { 'header' },
    isa => sub {
        die "$_[0] is not one of 'host', 'header' or 'full'" unless $_[0] =~ /^(host|header|full)$/;
    },
);


=method BUILD

Initialize the analyzer.

check host only :

    my $analyzer = Celogeek::SCK::Analyzer->new(uri => $url, method => 'host');

header only :

    my $analyzer = Celogeek::SCK::Analyzer->new(uri => $url, method => 'header');

full content :

    my $analyzer = Celogeek::SCK::Analyzer->new(uri => $url, method => 'full');

=cut

sub BUILD {
    my ($self) = @_;

    if ( $self->_is_valid_host( $self->uri->host() ) ) {
        $self->header( { status => '200 OK', } );
    }
    else {
        $self->header( { status => 'PORN/ILLEGAL', } );
    }

    return if $self->method() eq 'host';

    {
        my $request = $_ua_header->get( $self->uri );
        $self->_extract_header($request);
    }

    return if $self->method() eq 'header';
    return unless $self->header()->{status}       eq '200 OK';
    return unless $self->header()->{content_type} eq 'text/html';

    {
        my $request = $_ua_content->get( $self->uri );
        $self->_extract_content($request);
    }

    return;
}

####################### PRIVATE ##################

sub _is_valid_host {
    my ( $self, $host ) = @_;

    #check porno/illegal
    foreach my $rs(($_local_resolver, $_resolver)) {
        my $dns_message = $rs->search($host);
	if (defined $dns_message && $dns_message->can('answer')) {
		foreach my $rr ( $dns_message->answer ) {
		    next unless $rr->type eq 'A';
		    return 0 if $rr->address eq $_resolver_bad_ip;
		}
	}
    }
    return 1;
}

sub _extract_header {
    my ( $self, $request ) = @_;

    my $header = $request->header("Content-Type") // "text/html";
    my ( $content_type, $encoding )
        = split( ';', $header );
    $encoding //= "UTF-8";
    $encoding =~ s!charset=!!x;

    $self->header(
        {   status       => $self->_extract_status($request),
            content_type => $content_type,
            encoding     => uc($encoding),
        }
    );

    return;
}

sub _extract_content {
    my ( $self, $request ) = @_;

    #reset content
    $self->content( {} );

    $self->content(
        {   title         => $self->_extract_title($request),
            short_content => $self->_extract_short_content($request),
        }
    );

    return;
}

sub _extract_status {
    my ( $self, $request ) = @_;
    return $request->status_line;
}

sub _extract_title {
    my ( $self, $request ) = @_;

    #get content from html
    my ($title) = $request->content =~ m!<title[^>]*>(.+?)</title>!six;
    return unless defined $title;

    #recode data in utf-8

    #decode in perl format
    $title = Encode::decode( $self->header->{encoding}, $title );

    #decode entities
    decode_entities($title);

    #encode utf8
    $title = Encode::encode( "UTF-8", $title );

    #oneline html title
    $title =~ s![\r\n]! !gx;
    $title =~ s!\s+! !gx;

    #Remove white space
    $title =~ s!$RE{ws}{crop}!!gx;

    return $title;
}

sub _extract_short_content {
    my ( $self, $request ) = @_;

    my $content = $request->content;

    $content = Encode::decode( $self->header->{encoding}, $content );

    #decode entities
    decode_entities($content);

    #encode utf8
    $content = Encode::encode( "UTF-8", $content );

    my $extractor = HTML::ContentExtractor->new();
    $extractor->extract( $request->base, $content );

    #short content
    my $short_content = substr( $extractor->as_text(), 0, 500 );
    if ( length($content) > 500 ) {
        $short_content .= ' ...';
    }

    #oneline html short_content
    $short_content =~ s![\r\n]! !gx;
    $short_content =~ s!\s+! !gx;

    #Remove white space
    $short_content =~ s!$RE{ws}{crop}!!gx;

    return $short_content;
}

1;
