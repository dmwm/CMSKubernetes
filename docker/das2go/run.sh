#!/bin/bash
# get proxy
echo "USER=$USER"
/data/proxy.sh $USER
sleep 2
ls -la /data/srv/current/auth/proxy/proxy
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
