#!/bin/bash

user=$1
pdir=/data/srv/current/auth/proxy
if [ ! -d $pdir ]; then
    mkdir -p $pdir
fi
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo voms-proxy-init -voms cms -rfc -key /etc/secrets/robotkey.pem -cert /etc/secrets/robotcert.pem
    if [ -f /tmp/x509up_u0 ]; then
        # update proxy in /etc/secrets
        sudo cp /tmp/x509up_u0 /etc/secrets/proxy
        # temp fix: fix permissions of key files in secrets since they'll be reset
        sudo chmod 0400 /etc/secrets/robotkey.pem /etc/secrets/server.key /etc/secrets/hmac
        # update proxy in cmsweb auth area
        sudo cp /tmp/x509up_u0 $pdir/proxy
        sudo chown $user $pdir/proxy
        sudo chgrp $user $pdir/proxy
    fi
fi
