package App::Stats;

# ABSTRACT: App::Stats return stats for a shorten url

use strict;
use warnings;

use Dancer 'syntax';

#catch s=1 in queries, for stats
get qr{^/(.*)$}x => sub {
    my ($key) = splat;
    if (params->{s}) {
        my $base  = request->base()->as_string;
        my $url   = Celogeek::SCK->new( 'redis' => redis );
        my $stats = $url->stats( $key, { 'date' => "%c UTC" } );
        $stats->{shorturl} = $base . $stats->{path};
        return template 'stats', $stats;
    }
    pass;
};

1;
