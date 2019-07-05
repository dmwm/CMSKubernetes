#!/bin/bash
# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/das/proxy
    ln -s /etc/proxy/proxy /data/srv/state/das/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi
# start mongodb
mongod --config $WDIR/mongodb.conf
# upload DASMaps into MongoDB
das_js_import /data/DASMaps/js

# start das2go exporter
nohup das2go_exporter -address ":18217" 2>&1 1>& das2go_exporter.log < /dev/null &

# start das2go server
if [ -f /etc/secrets/dasconfig.json ]; then
    das2go_monitor -config /etc/secrets/dasconfig.json
else
    das2go_monitor -config $GOPATH/src/github.com/dmwm/das2go/dasconfig.json
fi
