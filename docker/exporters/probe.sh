#!/bin/bash

url=$1
ARCH=`ls $WDIR/srv/current/sw | grep ^slc`

# source curl environment to setup proper SSL
libs="curl openssl c-ares"
for lib in $libs; do
    v=`ls $WDIR/srv/current/sw/$ARCH/external/$lib/`
    source $WDIR/srv/current/sw/$ARCH/external/$lib/$v/etc/profile.d/init.sh
done

curl -k --key $X509_USER_PROXY --cert $X509_USER_PROXY "$url"
