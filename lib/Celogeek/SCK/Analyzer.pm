package Celogeek::SCK::Analyzer;

# ABSTRACT: Celogeek::SCK::Analyzer - Analyze content of title and populate database

use strict;
use warnings;
use 5.012;

use Data::Dumper;
use Carp;

use Moose;
use MooseX::Params::Validate;
use MooseX::Types::URI qw(Uri);

use Moose::Util::TypeConstraints;

use LWP::UserAgent;
use Encode;
use HTML::Entities ();
use HTML::ExtractMain qw(extract_mail_html);

use Regexp::Common qw(whitespace);

my $_ua_header = LWP::UserAgent->new;
$_ua_header->agent("Mozilla");
$_ua_header->timeout(10);
$_ua_header->max_size(2000);

my $_ua_content = LWP::UserAgent->new;
$_ua_content->agent("Mozilla");
$_ua_content->timeout(30);

subtype 'SCK:Method' => as 'Str' => where {
    $_ eq 'header'
      || $_ eq 'full';
};

=attr uri

URI to analyse

=cut

has uri => (
    isa      => Uri,
    coerce   => 1,
    is       => 'ro',
    required => 1,
);

=attr is_valid_uri

Status of URI, need to match some spec

=cut

has is_valid_uri => (
    isa      => "Bool",
    is       => "rw",
    required => 1,
    default  => 0,
);

=attr header

Content all usefull headers of uri

=cut

has header => (
    isa => 'HashRef',
    is  => 'rw',
);

=attr content

Content for url

=cut

has content => (
    isa => 'HashRef',
    is  => 'rw',
);

=attr method

Method of extraction

    header: extract header only
    full: get title, keywords, and category

=cut

has method => (
    isa      => 'SCK:Method',
    is       => 'rw',
    required => 1,
    default  => 'header',
);

sub BUILD {
    my ($self) = @_;

    $self->_check_uri();
    return unless $self->is_valid_uri();

    my $request = $_ua_header->get( $self->uri );
    $self->_extract_header($request);

    return if $self->method() eq 'header';

    my $request_full = $_ua_content->get( $self->uri );
    $self->_extract_content($request);

    return;
}

#Check if URI is valid
sub _check_uri {
    my ($self) = @_;

    #no short uri
    unless (
        $self->uri->host =~ m!
        ^sck\.to$ |
        ^susbck\.com$ |
        ^url\.celogeek\.(fr|com)$
        !x
      )
    {
        if ( $self->uri->scheme eq 'http' || $self->uri->scheme eq 'https' ) {
            $self->is_valid_uri(1);
        }
    }
    return $self->is_valid_uri();
}

sub _extract_header {
    my ( $self, $request ) = @_;

    my ( $content_type, $encoding ) =
      split( ';', $request->header("Content-Type") );
    $encoding //= "UTF-8";
    $encoding =~ s!charset=!!x;

    $self->header(
        {
            status       => $request->status_line,
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
    return unless $self->header()->{status}       eq '200 OK';
    return unless $self->header()->{content_type} eq 'text/html';

    $self->content(
        {
            analyzer => 1,
            title    => $self->_extract_title($request),
        }
    );

    return;
}

sub _extract_title {
    my ( $self, $request ) = @_;

    if (   $self->header->{status} eq '200 OK'
        && $self->header->{content_type} eq 'text/html' )
    {

        #get content from html
        my ($title) = $request->content =~ m!<title[^>]*>(.+?)</title>!six;
        return unless defined $title;

        #recode data in utf-8
        Encode::from_to( $title, $self->header->{encoding}, "UTF-8" );

        #oneline html title
        $title =~ s![\r\n]! !gx;
        $title =~ s!\s+! !gx;

        #Remove white space
        $title =~ s!$RE{ws}{crop}!!gx;

        return $title;
    }

    return;
}

sub _extract_words {
    my ($self) = @_;
}

1;
