package Celogeek::SCK::Store::Base;

# ABSTRACT: Empty store, to force implementation of method

use strict;
use warnings;
# VERSION

use Moo::Role;

sub _die {
    my $self = shift;
    my $store_class = substr(__PACKAGE__,0,-length('Base')).ucfirst($self->engine);
    my $func = substr((caller(1))[3], length(__PACKAGE__) + 2);
    die "${store_class}::${func} need to be implemented";
}

#method need to be implemented
for my $meth (qw/
        validate_connection
    /) {
    eval <<EOF
    sub $meth { shift->_die }
EOF
    ;
}

1;
