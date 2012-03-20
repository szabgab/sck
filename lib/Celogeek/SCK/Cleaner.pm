package Celogeek::SCK::Cleaner;

# ABSTRACT: Celogeek::SCK::Analyzer - Analyze content of title and populate database

use strict;
use warnings;
use 5.014;

# VERSION

use Data::Dumper;
use Carp;

use Moo;
use MooX::Options;
use URI;
use Regexp::Common qw/number/;

option 'run' => (
    doc           => 'remove bad link effectivly',
    is            => 'rw',
);

=method is_valid_uri

Check if URI is valid

=cut

sub is_valid_uri {
    my ( $self, %opts ) = @_;
    my $uri = $opts{uri};
    ref $uri eq 'URI'
        or $uri = URI->new($uri);

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
