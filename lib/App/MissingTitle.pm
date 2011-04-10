package App::MissingTitle;

# ABSTRACT: App::MissingTitle get missing title from TOP10

=head1 DESCRIPTION

Fetch missing title for a specific url, save it, and redirect to a transparent picture

=cut

=head1 SYNOPSIS

    <img src="http://sck.to/u?mt=1" />

=cut

use strict;
use warnings;
use 5.012;

use Dancer ':syntax';

get qr{^/(.+)$}x => sub {
    return pass() unless defined params->{mt};

    my ($key) = splat();

    my $longurl = vars->{sck}->enlarge($key);
    if ( $longurl ne '' ) {
        vars->{sck}->missing_title($longurl);
    }

    return redirect vars->{base} . 'images/transp.gif';
};

1;
