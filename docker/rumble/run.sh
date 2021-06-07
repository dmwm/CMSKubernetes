#!/bin/bash

# Kerberos
keytab=/etc/rumble/keytab
principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
echo "principal=$principal"
kinit $principal -k -t "$keytab"
if [ $? == 1 ]; then
    echo "Unable to perform kinit"
    exit 1
fi
klist -k "$keytab"

git clone https://github.com/mrceyhun/CMSMonitoring.git && \
    cp -R CMSMonitoring/src/go/Rumble/* $WDIR && \
    go build rumble_server.go && \
    chmod 755 $WDIR/rumble_server && \
    ./rumble_server
