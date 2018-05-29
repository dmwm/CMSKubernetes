#!/bin/bash
# get proxy
echo "USER=$USER"
/data/proxy.sh $USER
ls -la /data/srv/current/auth/proxy/proxy
sleep 2
# start server
if [ -f /etc/secrets/tfaas-config.json ]; then
    echo "Start with /etc/secrets/tfaas-config.json"
    cat /etc/secrets/tfaas-config.json
    tfaas -config /etc/secrets/tfaas-config.json
else
    echo "Start with $PWD/config.json"
    cat $PWD/config.json
    tfaas -config $PWD/config.json
fi
