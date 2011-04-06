package App::Error;

# ABSTRACT: App::Error is a error message translator for the App

=head1 DESCRIPTION

App::Error convert throw messages from SCK into a readable message for visitor

=cut

use strict;
use warnings;

#Error message known
my $_error_msg = {
    "NO WAY TO SHORTEN" => "Impossible to shorten this URL",
    "BAD URL" =>
      "Your url is bad. It has to start with 'http://' or 'https://'.",
    "TOO MANY TRIES" => "Too many tries (> %d). Try again.",
    "THIS KEY DOESNT EXIST" => "This tinyurl doesn't exist"
};

=method get_error_message_from

Return the readable message from SCK error code

=cut

sub get_error_message_from {
    my $self        = shift;
    my $error_throw = shift;
    my $max_tries   = shift || 0;

    #extract code from error throw, try to find a match, or throw the error
    my ($error_code) = $error_throw =~ m!^SCK\[(.*?)\]!x;
    if ( defined $error_code && exists $_error_msg->{$error_code} ) {
        return sprintf( $_error_msg->{$error_code}, $max_tries );
    }
    else {
        croak $error_throw;
    }
}

1;
