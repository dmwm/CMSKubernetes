#!/bin/bash
# get proxy
echo "USER=$USER"
sudo /data/proxy.sh $USER
ls -la /data/srv/current/auth/proxy/proxy
# start mongodb
mongod --config $WDIR/mongodb.conf
# upload DASMaps into MongoDB
das_js_import /data/DASMaps/js localhost 8230
# start das2go server
if [ -f /etc/secrets/dasconfig.json ]; then
    das2go_server /etc/secrets/dasconfig.json
else
    das2go_server $GOPATH/src/github.com/dmwm/das2go/dasconfig.json
fi
