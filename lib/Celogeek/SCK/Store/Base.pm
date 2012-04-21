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
        get_by_url
        set_by_url
        exists_by_url
        increment_by_url
        get_by_shorturl
        set_by_shorturl
        exists_by_shorturl
        increment_by_shorturl
        increment_top10_by_url
        increment_stat
        increment_top10_by_shorturl
        url_from_shorturl
        top10
        reset_top10
        all_by_url
        del_by_url
    /) {
    eval <<EOF
    sub $meth { shift->_die }
EOF
    ;
}

1;
