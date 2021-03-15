#!/bin/bash

# overwrite proxy if it is present in /etc/proxy
mkdir -p /data/srv/state/dbs/proxy
mkdir -p /data/srv/current/auth/proxy
if [ -f /etc/proxy/proxy ]; then
    ln -s /etc/proxy/proxy /data/srv/state/dbs/proxy/proxy.cert
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# check for tnsnames.ora
if [ -f /etc/secrets/tnsnames.ora ]; then
    export TNS_ADMIN=/etc/secrets/tnsnames.ora
fi

export LD_LIBRARY_PATH=`find /usr/lib/oracle -name libocci.so | sed -e "s,/libocci.so,,g"`
# start dbs2go server
if [ -f /etc/secrets/dbsconfig.json ]; then
    sudo cp /etc/secrets/dbfile /data/srv/current/auth/proxy/dbfile
    sudo chown $USER.$USER /data/srv/current/auth/proxy/dbfile
    sudo chmod 0400 /data/srv/current/auth/proxy/dbfile
    echo "ls /data/srv/current/auth/proxy"
    ls -la /data/srv/current/auth/proxy/
    echo "X509_USER_PROXY=$X509_USER_PROXY"
    echo "start with /etc/secrets/dbsconfig.json"
    /data/dbs2go -config /etc/secrets/dbsconfig.json
else
    echo "start with $PWD/config.json"
    /data/dbs2go -config /data/config.json
fi
