#!/bin/bash
echo "dbs_start.sh"
ls -al /etc/secrets
# start dbs2go server
cd $GOPATH/src/github.com/vkuznet/dbs2go
if [ -f /etc/secrets/dbsconfig.json ]; then
    echo "start with /etc/secrets/dbsconfig.json"
    dbs2go -config /etc/secrets/dbsconfig.json
else
    echo "start with $PWD/dbsconfig.json"
    dbs2go -config dbsconfig.json
fi
