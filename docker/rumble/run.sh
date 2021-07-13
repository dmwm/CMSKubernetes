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

# run rumble_server
$WDIR/rumble_server
