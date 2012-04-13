package Celogeek::SCK::Store::Redis;

# ABSTRACT: Redis store engine

use strict;
use warnings;
use Carp;
# VERSION
use 5.012;

use Moo::Role;

sub validate_connection {
    my $self = shift;
    croak "not a Redis connection" unless ref $self->connection && $self->connection->isa('Redis');
}

1;
