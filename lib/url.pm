package url;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::Redis;
use Celogeek::URL;
use CGI;

our $VERSION = '0.1';

any [ 'get', 'post' ] => '/' => sub {
    my $base        = request->base()->as_string;
    my $longurl     = params->{url};
    my $max_letters = length($longurl) - length($base) - 1;
    my $url         = Celogeek::URL->new(
        'redis'             => redis,
        max_generated_times => 5,
        max_letters         => $max_letters
    );
    my $shorturl = "";
    my $statsurl = "";
    my $warning  = "";
    my $top10    = [];

    #top10 not for bookmarklet
    if ( !params->{b} ) {
        $top10 = $url->top10();
    }

    if ($longurl) {
        my $short = $url->shorten($longurl);

        if ( $short eq 'NO WAY TO SHORTEN' ) {
            $warning .= "Impossible to shorten this URL";
        }
        elsif ( $short eq 'BAD URL' ) {
            $warning .=
              "Your url is bad. It has to start with 'http://' or 'https://'.";
        }
        elsif ( $short eq 'TOO MANY TRIES' ) {
            $warning .=
                "Too many tries (> "
              . $url->max_generated_times
              . "). Try again.";
        }
        else {
            $shorturl = $base . $short;
            $statsurl = $shorturl . "?s=1";
            if ( $url->generated_times ) {
                $warning .=
                  "Generated after " . $url->generated_times . " tries.";
            }
            else {
                $warning .= "Already registered in database";
            }
        }
    }

    #api
    if ( params->{a} ) {
        content_type "text/plain";
        return $shorturl ne "" ? $shorturl : $longurl;
    }
    else {
        content_type "text/html";
        if ( params->{t} ) {
            my @title = ();
            push @title, params->{title} if params->{title};
            push @title, $shorturl ne "" ? $shorturl : $longurl;
            my $title_str = CGI::escape( join( ' - ', @title ) );
            return redirect "http://twitter.com/?status=" . $title_str;
        }
        else {
            template params->{b} ? 'bookmarlet' : 'index',
              {
                url      => $longurl,
                shorturl => $shorturl,
                statsurl => $statsurl,
                warning  => $warning,
                top10    => $top10
              };
        }
    }
};

get qr{/(.*)$} => sub {
    my ($key) = splat;
    if ( params->{s} ) {
        _stats_url($key);
    }
    elsif ( params->{mt} ) {
        _missing_title_url($key);
    }
    else {
        _go_url($key);
    }
};

sub _missing_title_url {
    my $base    = request->base()->as_string;
    my $key     = shift;
    my $url     = Celogeek::URL->new( 'redis' => redis );
    my $longurl = $url->longen($key);
    if ( $longurl ne '' ) {
        $url->missing_title($longurl);
    }
    return redirect $base. "images/transp.gif";
}

sub _go_url {
    my $base        = request->base()->as_string;
    my $key         = shift;
    my $url         = Celogeek::URL->new( 'redis' => redis );
    my $click       = 1;
    my $click_uniq  = 0;
    my $cookie_name = join( "_", "sck", $key );
    $cookie_name =~ s/\/+/_/g;
    unless ( defined cookies->{$cookie_name} ) {
        set_cookie $cookie_name => "1", expires => ( time + 86400 );
        $click_uniq = 1;
    }
    my $longurl = $url->longen( $key, $click, $click_uniq );
    $longurl = $base if $longurl eq '';
    return redirect $longurl;
}

sub _stats_url {
    my $base  = request->base()->as_string;
    my $key   = shift;
    my $url   = Celogeek::URL->new( 'redis' => redis );
    my $stats = $url->stats( $key, { 'date' => "%c UTC" } );
    template 'stats', $url->stats( $key, { 'date' => "%c UTC" } );
}

true;
