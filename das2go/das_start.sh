#!/bin/bash
# start mongodb
mongod --config $WDIR/mongodb.conf
# upload DASMaps into MongoDB
das_js_import /data/DASMaps/js localhost 8230
# start das2go server
#das_server $GOPATH/src/github.com/dmwm/das2go/das.json 2>&1 1>& das.log < /dev/null &
das_server $GOPATH/src/github.com/dmwm/das2go/das.json 2>&1 1>& das.log
#sleep 10
# show the running processes
#ps auxwww | egrep "das|mongo"
