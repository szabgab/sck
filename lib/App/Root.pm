package App::Root;

# ABSTRACT: Roo App for Dancer APP SCK

=head1 DESCRIPTION

Root App for the dancer app SCK. This part manage request on "/" only

=cut

use strict;
use warnings;
use 5.012;

#Initialise dancer app
use Dancer ':syntax';
use Try::Tiny;
use URI::Escape;

#Load SCK module
use App::Error;

#api, call with a=1
any [ 'get', 'post' ] => '/' => sub {
    return pass() unless defined params->{a} && defined params->{url};
    content_type "text/plain";
    try {
        return vars->{base} . vars->{sck}->shorten( params->{url} );
    }
    catch {
        #if any error on getting short url, return long
        return params->{url};
    };
};

#twitter, call with t=1
any [ 'get', 'post' ] => '/' => sub {
    return pass() unless defined params->{t} && defined params->{url};

    my @title = ();
    push @title, params->{title} if params->{title};

    try {
        push @title, vars->{base} . vars->{sck}->shorten( params->{url} );
    }
    catch {
        #push long title if any error occur
        push @title, params->{url};

    };

    return redirect( "http://twitter.com/?status="
          . uri_escape_utf8( join( ' - ', @title ) ) );
};

#normal call with url
any [ 'get', 'post' ] => '/' => sub {
    return pass() unless defined params->{url};

    my (
        $short_url,      $stats_url, $error_message,
        $notice_message, $top10_members
    );

    try {
        $short_url = vars->{base} . vars->{sck}->shorten( params->{url} );
        $stats_url = $short_url . "?s=1";
        if ( vars->{sck}->generated_times ) {
            $notice_message =
              "Generated after " . vars->{sck}->generated_times . " tries.";
        }
        else {
            $notice_message = "Already registered in database";
        }
    }
    catch {
        $error_message =
          App::Error->get_error_message_from( $_,
            { MAX_GENERATED_TIMES => vars->{sck}->max_generated_times } );
    };

    #display the right template
    my $tpl = "index";
    my $opt = {};

    #bookmarklet (the window box)
    if ( params->{b} ) {
        $tpl = "bookmarklet.tt";
    }

    #The main form, call in ajax, return the shorten link
    if ( params->{x} ) {
        $tpl = "_shortenlinks.tt";
        $opt = { layout => undef };
    }

    #The main template, add top10
    if ( $tpl eq "index" ) {
        $top10_members = vars->{sck}->top10();
    }

    return template(
        $tpl,
        {
            url            => params->{url},
            short_url      => $short_url,
            stats_url      => $stats_url,
            top10_members  => $top10_members,
            notice_message => $notice_message,
            error_message  => $error_message,
            bookmarklet    => params->{b},
        },
        $opt
    );
};

#no params, display the normal website
get '/' => sub {
    return template(
        "index",
        {
            top10_members         => vars->{sck}->top10(),
            bookmarklet_installed => params->{ib},
        }
    );
};

1;

