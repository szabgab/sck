package Celogeek::SCK::Cleaner;

# ABSTRACT: Celogeek::SCK::Analyzer - Analyze content of title and populate database

use strict;
use warnings;
use 5.012;

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

#Check if URI is valid
sub is_valid_uri {
    my ( $self, $uri ) = validated_list(
        \@_,
        uri => {
            isa    => Uri,
            coerce => 1,
        }
    );

    #no short uri
    unless (
        $uri->host =~ m!
        ^sck\.to$ |
        ^susbck\.com$ |
        ^url\.celogeek\.(fr|com)$
        !x
      )
    {
        if ( $uri->scheme eq 'http' || $uri->scheme eq 'https' ) {
            return 1;
        }
    }
    return;
}

1;
