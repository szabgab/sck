package App::Stats;

# ABSTRACT: App::Stats return stats for a shorten url

=head1 DESCRIPTION

This is the stats module, it will show all stats information concerning your tiny url

=cut

use strict;
use warnings;
use 5.012;

use Dancer ':syntax';

#catch s=1 in queries, for stats
get qr{^/(.+)$}x => sub {
    return pass() unless defined params->{s};

    my ($key) = splat;
    my $stats_info_ref = vars->{sck}->stats( $key, 'date_format' => '%c UTC' );
    $stats_info_ref->{short_url} = vars->{base} . $stats_info_ref->{path};
    return template( 'stats', $stats_info_ref );
};

1;
