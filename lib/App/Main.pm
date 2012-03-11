package App::Main;

# ABSTRACT: Main App for Dancer APP SCK

=head1 DESCRIPTION

Main App for the dancer app SCK. This part manage request on "/" only

=cut

use strict;
use warnings;
use 5.014;

# VERSION

#Initialise dancer app
use Dancer ':syntax';
use Dancer::Plugin::Redis 0.03;

#Load SCK module
use Celogeek::SCK;

#Initialize variable before any root
hook before => sub {

    #the base url, use in short link
    var base => request->base()->as_string();

    #sck url tools to reduce link
    #set default settings, max_letters could be set later
    var sck => Celogeek::SCK->new(
        'redis'               => redis,
        'max_generated_times' => 5,
    );

    #set max letter if url is pass
    if ( defined params->{url} ) {

        #always try to generate a shorter link that the long url
        vars->{sck}->max_letters(
            length( params->{url} ) - length( vars->{base} ) - 1 );
    }

    #if api set lighter check method
    if ( defined params->{a} ) {
        vars->{sck}->check_method('host');
    }
};

1;
