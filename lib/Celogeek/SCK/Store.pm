package Celogeek::SCK::Store;

# ABSTRACT: handle storage of SCK website

use strict;
use warnings;
# VERSION
use Moo;

has 'engine' => (
    is => 'ro',
    required => 1,
);

has 'connection' => (
    is => 'ro',
    required => 1,
);

sub BUILD {
    my $self = shift;
    my $store = __PACKAGE__.'::'.ucfirst($self->engine);
    with $store;
    with __PACKAGE__.'::Base';
    $self->validate_connection();
}

1;
