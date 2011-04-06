package App::MissingTitles;

# ABSTRACT: App::MissingTitles get missing title from TOP10

use strict;
use warnings;

use Dancer 'syntax';

#catch s=1 in queries, for stats
get qr{^/(.*)$}x => sub {
    my ($key) = splat;
    if ( params->{mt} ) {
        my $base    = request->base()->as_string;
        my $url     = Celogeek::SCK->new( 'redis' => redis );
        my $longurl = $url->longen($key);
        if ( $longurl ne '' ) {
            $url->missing_title($longurl);
        }
        return redirect $base. "images/transp.gif";
    }
    pass;
};

1;
