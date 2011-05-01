package Celogeek::SCK::Cleaner;

# ABSTRACT: Celogeek::SCK::Analyzer - Analyze content of title and populate database

use strict;
use warnings;
use 5.012;

# VERSION

use Data::Dumper;
use Carp;

use Moose;
with 'MooseX::Getopt';
use MooseX::Params::Validate;
use MooseX::Types::URI qw(Uri);

has 'run' => (
    documentation => 'remove bad link effectivly',
    is            => 'rw',
    isa           => 'Bool',
    required      => 1,
    default       => 0,
);

=method is_valid_uri

Check if URI is valid

=cut

sub is_valid_uri {
    my ( $self, @opts ) = @_;
    my ($uri) = validated_list(
        \@opts,
        uri => {
            isa    => Uri,
            coerce => 1,
        }
    );

    my @bad_url_regexes = (
        qr{^localhost$}x,               qr{^localhost:}x,
        qr{^sck\.to$}x,                 qr{^susbck\.com$}x,
        qr{^url\.celogeek\.(fr|com)$}x, qr{^\d+\.\d+\.\d+\.\d+$}x,
    );

    if ( $uri->scheme eq 'http' || $uri->scheme eq 'https' ) {
        foreach my $bad_url_regex (@bad_url_regexes) {
            return if $uri->host =~ $bad_url_regex;
        }
        return 1;
    }
    else {
        return;
    }
}

1;
