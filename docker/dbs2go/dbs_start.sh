#!/bin/bash
# start dbs2go server
cd $GOPATH/src/github.com/vkuznet/dbs2go
if [ -f /etc/secrets/dasconfig.json ]; then
    dbs2go -config /etc/secrets/dbsconfig.json
else
    dbs2go -config dbsconfig.json
fi
