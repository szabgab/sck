#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Dancer::Test;
Dancer::set environment => 'testing';
Dancer::Config->load;
require 't/SCK/engine/'.Dancer::config->{store}->{engine}.'_unload.ttt';

done_testing;
