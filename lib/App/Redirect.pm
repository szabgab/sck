package App::Redirect;

# ABSTRACT: App::Redirect redirect to the long url

=head1 DESCRIPTION

This module redirect to the long url, or return it if a=1 has been pass as args

=cut

use strict;
use warnings;
use 5.014;
use Carp;
use Try::Tiny;

# VERSION

use Dancer ':syntax';
use HTTP::BrowserDetect;

#API part : params a=1
get qr{^/(.+)$}x => sub {
    return pass() unless defined params->{a};

    content_type('text/plain');

    #try enlarge key if exist
    my ($key) = splat();
    my $longurl;
    try {
        $longurl = vars->{sck}->enlarge($key);
    };
    $longurl = vars->{base} unless defined $longurl;

    return $longurl;
};

#Normal part
get qr{^/(.+)$}x => sub {
    my ($key) = splat();

    #detect browser
    my $browser = HTTP::BrowserDetect->new();

    #always count click, but use cookie to detect new clic_uniq
    my $click      = 0;
    my $click_uniq = 0;

    #we do count only if it's not a robot
    unless ( $browser->robot() ) {
        $click = 1;

        #detect if cookie exist, and add 1 clic_uniq if it's not the case
        my $cookie_name = join( '_', 'sck', $key );
        $cookie_name =~ s!/+!_!xg;
        unless ( defined cookies->{$cookie_name} ) {
            set_cookie( $cookie_name => '1', expires => ( time + 86400 ) );
            $click_uniq = 1;
        }
    }

    #take long url and redirect
    my $longurl;
    try {
        $longurl = vars->{sck}->enlarge(
            $key,
            clicks      => $click,
            clicks_uniq => $click_uniq
        );
    };
    $longurl = vars->{base} unless defined $longurl;
    return redirect($longurl);
};

1;
