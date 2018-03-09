#!/bin/bash
# start mongodb
mongod --config $WDIR/mongodb.conf
# upload DASMaps into MongoDB
das_js_import /data/DASMaps/js localhost 8230
# start das2go server
das_server $GOPATH/src/github.com/dmwm/das2go/dasconfig.json 2>&1 1>& das.log
