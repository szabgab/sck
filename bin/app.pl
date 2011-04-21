#!/usr/bin/env perl

# PODNAME: AppLauncher
# ABSTRACT: load all App in the right order

use strict;
use warnings;
use 5.012;

use Dancer;

#Main : define common shared vars
use App::Main;

#Root : Match only /
use App::Root;

#Stats : Match any short url with params s=1
use App::Stats;

#Redirect : redirect to the long url, accept api a=1
#This part should be execute after all overs
use App::Redirect;

#dance
dance;
