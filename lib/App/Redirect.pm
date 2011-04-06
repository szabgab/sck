package App::Redirect;

# ABSTRACT: App::Stats return stats for a shorten url

use strict;
use warnings;

use Dancer 'syntax';

#catch s=1 in queries, for stats
get qr{^/(.*)$}x => sub {
    my ($key) = splat;
    my $base = request->base()->as_string;
    my $url  = Celogeek::SCK->new( 'redis' => redis );
    if ( params->{a} ) {
        my $longurl = $url->longen($key);
        $longurl = $base if $longurl eq '';
        content_type "text/plain";
        return $longurl;
    }
    else {
        my $click       = 1;
        my $click_uniq  = 0;
        my $cookie_name = join( "_", "sck", $key );
        $cookie_name =~ s/\/+/_/xg;
        unless ( defined cookies->{$cookie_name} ) {
            set_cookie $cookie_name => "1", expires => ( time + 86400 );
            $click_uniq = 1;
        }
        my $longurl = $url->longen( $key, $click, $click_uniq );
        $longurl = $base if $longurl eq '';
        return redirect $longurl;
    }
    pass;
};

1;
