package App::Main;

# ABSTRACT: Main App for Dancer APP SCK

=head1 DESCRIPTION

Main App for the dancer app SCK

=cut

use strict;
use warnings;
use 5.012;

#Initialise dancer app
use Try::Tiny;
use Dancer ':syntax';
use Dancer::Plugin::Redis;

#Load helper
use App::Error;

#Load SCK module
use Celogeek::SCK;
use URI::Escape;

#Main app, return a shorten url or a long url
any [ 'get', 'post' ] => '/' => sub {
    my $base        = request->base()->as_string;
    my $longurl     = params->{url} // "";
    my $max_letters = length($longurl) - length($base) - 1;
    my $url         = Celogeek::SCK->new(
        'redis'               => redis,
        'max_generated_times' => 5,
        'max_letters'         => $max_letters
    );
    my $shorturl = "";
    my $statsurl = "";
    my $error    = "";
    my $notice   = "";
    my $top10    = [];

    if ($longurl) {
        try {
            my $short = $url->shorten($longurl);
            $shorturl = $base . $short;
            $statsurl = $shorturl . "?s=1";
            if ( $url->generated_times ) {
                $notice =
                  "Generated after " . $url->generated_times . " tries.";
            }
            else {
                $notice = "Already registered in database";
            }
        }
        catch {
            $error =
              App::Error->get_error_message_from( $_,
                { MAX_GENERATED_TIMES => $url->max_generated_times } );
        }
    }

    #api
    if ( params->{a} ) {
        content_type "text/plain";
        return $shorturl ne "" ? $shorturl : $longurl;
    }
    else {
        if ( params->{t} ) {
            my @title = ();
            push @title, params->{title} if params->{title};
            push @title, $shorturl ne "" ? $shorturl : $longurl;
            my $title_str = uri_escape_utf8( join( ' - ', @title ) );
            return redirect "http://twitter.com/?status=" . $title_str;
        }
        else {
            my $tpl = "index";
            my $opt = {};
            if ( params->{b} ) {
                $tpl = "bookmarklet.tt";
            }
            if ( params->{x} ) {
                $tpl = "_shortenlinks.tt";
                $opt = { layout => undef };
            }
            if ( $tpl eq "index" ) {
                $top10 = $url->top10();
            }
            return template $tpl,
              {
                url                   => $longurl,
                shorturl              => $shorturl,
                statsurl              => $statsurl,
                top10                 => $top10,
                notice                => $notice,
                error                 => $error,
                bookmarklet           => params->{b},
                bookmarklet_installed => params->{ib}
              }, $opt;
        }
    }
};

1;
