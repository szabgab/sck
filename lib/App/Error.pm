package App::Error;

# ABSTRACT: App::Error is a error message translator for the App

=head1 DESCRIPTION

App::Error convert throw messages from SCK into a readable message for visitor

=cut

use strict;
use warnings;
use 5.012;

use Carp;

#Error message known
my $_error_msg = {
    'NO WAY TO SHORTEN' => qq{Impossible to shorten this URL},
    'BAD URL' =>
        qq{Your url is bad. It has to start with 'http://' or 'https://'.},
    'TOO MANY TRIES'        => qq{Too many tries (> %d). Try again.},
    'THIS KEY DOESNT EXIST' => qq{This tinyurl doesn't exist},
    'PORN/ILLEGAL'          => qq{Porn or illegal link are not accepted},
    'UNREACHABLE HOST'      => qq {Can't access to this host, response is %s},
};

=method get_error_message_from

Return the readable message from SCK error code

    App::Error->get_error_message_from($croak_message, $max_tries);

=cut

sub get_error_message_from {
    my ( $self, $error_throw, $opts ) = @_;

    #extract code from error throw, try to find a match, or throw the error
    my ($error_code) = $error_throw =~ m!^SCK:\[(.*?)\]!x;
    if ( defined $error_code && exists $_error_msg->{$error_code} ) {
        if ( $error_code eq 'TOO MANY TRIES' ) {
            return sprintf(
                $_error_msg->{$error_code},
                $opts->{MAX_GENERATED_TIMES} // 0
            );
        }
        elsif ( $error_code eq 'UNREACHABLE HOST' ) {
            return sprintf(
                $_error_msg->{$error_code},
                $opts->{STATUS} // "UNKNOWN"
            );
        }
        else {
            return sprintf( $_error_msg->{$error_code} );
        }
    }
    else {
        croak $error_throw;
    }
}

1;
