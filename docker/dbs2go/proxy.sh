#!/bin/bash

user=$1
pdir=/data/srv/current/auth/proxy
if [ ! -d $pdir ]; then
    mkdir -p $pdir
fi
# TMP solution until k8s fix file permission for secret volume
# https://github.com/kubernetes/kubernetes/issues/34982
if [ ! -f /data/certs/robotkey.pem ] && [ -f /etc/secrets/robotkey.pem ]; then
    cp /etc/secrets/robotkey.pem /data/certs
    chmod 0400 /data/certs/robotkey.pem
fi
if [ ! -f /data/certs/robotcert.pem ] && [ -f /etc/secrets/robotcert.pem ]; then
    cp /etc/secrets/robotcert.pem /data/certs
fi
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo voms-proxy-init -voms cms -rfc -key /data/certs/robotkey.pem -cert /data/certs/robotcert.pem
    if [ -f /tmp/x509up_u0 ]; then
        # update proxy in cmsweb auth area
        sudo cp /tmp/x509up_u0 $pdir/proxy
        sudo chown $user $pdir/proxy
        sudo chgrp $user $pdir/proxy
        sudo rm /tmp/x509up_u0
    fi
fi
