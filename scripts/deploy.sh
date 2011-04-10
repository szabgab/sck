#!/bin/sh

set -x
set -e

RFILE=$1
RDIR=${RFILE/.tar.gz}
RPATH=/var/www/sck

echo "Deploy : $RFILE"
mkdir -p "$RPATH"
rm -rf "$RPATH"/"$RDIR"
tar xzf "$RFILE" -C "$RPATH"
[ -e "$RPATH"/current ] && unlink "$RPATH"/current
ln -s "$RDIR" "$RPATH"/current

