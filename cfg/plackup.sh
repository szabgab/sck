#!/usr/local/bin/bash

#IF YOU USE PERLBREW, setup your path, uncomment here
#export PATH=/usr/local/geist/perlbrew/perls/tinyurl/bin:$PATH

#PERLBREW_ROOT=/usr/local/geist/perlbrew; export PERLBREW_ROOT
#source /usr/local/geist/perlbrew/etc/bashrc

#perlbrew switch tinyurl
#hash -r
#IF YOU USE PERLBREW, setup your path, uncomment here

#set your project path
cd YOUR_PROJECT_PATH
sudo -u www plackup -E production -s Starman --workers=2 -l THE_PASS_OF_YOUR_PLACKUP_SOCKET_HERE.sock -a bin/app.pl


