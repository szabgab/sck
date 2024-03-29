#!/usr/bin/env bash

set -x
set -e

RFILE=$1
RDIR=${RFILE/.tar.gz}
RPATH=/var/www/sck

echo "Deploy : $RFILE"
mkdir -p "$RPATH"
rm -f /tmp/config.yml.backup
if [ -e "$RPATH"/current ]
then
    cp "$RPATH"/current/config.yml /tmp/config.yml.backup
    unlink "$RPATH"/current
fi
rm -rf "$RPATH"/"$RDIR"
tar xzf "$RFILE" -C "$RPATH"
ln -s "$RDIR" "$RPATH"/current
if [ -e "/tmp/config.yml.backup" ]
then
    cp /tmp/config.yml.backup "$RPATH"/current/config.yml
else
    cp "$RPATH"/current/config.yml.example "$RPATH"/current/config.yml
fi
sudo kill $(ps ax | grep 'starman master' | grep -v grep | awk '{print $1}')

