#!/bin/bash
# start server
conf=$PWD/config.json
if [ -f /etc/secrets/config.json ]; then
    conf=/etc/secrets/config.json
fi
echo "Start with $conf"
cat $conf
tfaas -config $conf
