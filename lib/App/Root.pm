package App::Root;

# ABSTRACT: Root App for Dancer APP SCK

=head1 DESCRIPTION

Root App for the dancer app SCK. This part manage request on "/" only

=cut

use strict;
use warnings;
use 5.014;
use Carp;
use Data::Dumper;

# VERSION

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

    my $fetch_title = params->{title} // vars->{sck}->title(params->{url}) // "";
    my @title = ($fetch_title);

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

#facebook, call with f=1
any [ 'get', 'post' ] => '/' => sub {
    return pass() unless defined params->{f} && defined params->{url};

    my $title = params->{title} // vars->{sck}->title(params->{url}) // "";
    my $url;

    try {
        $url = vars->{base} . vars->{sck}->shorten( params->{url} );
    }
    catch {

        #push long title if any error occur
        $url = params->{url};
    };

    return redirect( "http://www.facebook.com/share.php" . "?u="
          . uri_escape_utf8($url) . "&t="
          . uri_escape_utf8($title) );
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
        $error_message = App::Error->get_error_message_from(
            $_,
            {
                MAX_GENERATED_TIMES => vars->{sck}->max_generated_times,
                STATUS              => vars->{sck}->status,
            }
        );
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
            version        => $Celogeek::SCK::VERSION,
        },
        $opt
    );
};

#no params, display the normal website
get qr{^/(.*)$}x => sub {
    my ($path) = splat;
    return pass() if $path && !params->{s};
    my $stats_info_ref;
    if ( $path ) {
        $stats_info_ref =
          vars->{sck}->stats( $path, 'date_format' => '%c UTC' );
        $stats_info_ref->{short_url} = vars->{base} . $stats_info_ref->{path};
        $stats_info_ref->{version}   = $Celogeek::SCK::VERSION;
    }
    return template(
        "index",
        {
            top10_members         => vars->{sck}->top10(),
            bookmarklet_installed => params->{ib},
            version               => $Celogeek::SCK::VERSION,
            stats                 => $stats_info_ref,
        }
    );
};

1;

