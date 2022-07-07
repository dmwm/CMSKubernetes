#!/bin/bash

# overwrite proxy if it is present in /etc/proxy
#mkdir -p /data/srv/state/dbs/proxy
#mkdir -p /data/srv/current/auth/proxy
#if [ -f /etc/proxy/proxy ]; then
#    ln -s /etc/proxy/proxy /data/srv/state/dbs/proxy/proxy.cert
#    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
#fi

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# check for tnsnames.ora
if [ -f /etc/secrets/tnsnames.ora ]; then
    export TNS_ADMIN=/etc/secrets/tnsnames.ora
    if [ ! -f /etc/tnsnames.ora ]; then
        ln -s /etc/secrets/tnsnames.ora /etc/tnsnames.ora
    fi
fi
echo TNS_ADMIN=$TNS_ADMIN

export LD_LIBRARY_PATH=`find /usr/lib/oracle -name libocci.so | sed -e "s,/libocci.so,,g"`
# start dbs2go server
if [ -f /etc/secrets/dbsconfig.json ]; then
    echo "start with /etc/secrets/dbsconfig.json"
    /data/dbs2go -config /etc/secrets/dbsconfig.json
else
    echo "start with $PWD/config.json"
    /data/dbs2go -config /data/config.json
fi
