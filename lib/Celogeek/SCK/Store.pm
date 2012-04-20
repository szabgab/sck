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

sub new_with_config {
    my $class = shift;
    my ($config) = @_;
    my $config_class = $config->{class};
    my $config_keyword = $config->{keyword};
    eval <<EOF
    package MyConf;
    use strict;
    use warnings;
    use Dancer ':syntax';
    use $config_class;
    sub connection { $config_keyword }
    1;
EOF
    ;
    $class->new(engine => $config->{engine}, connection => MyConf->connection);
}

1;
