#!/bin/bash
# start dbs2go server
cd $GOPATH/src/github.com/vkuznet/dbs2go
dbs2go -config dbsconfig.json 2>&1 1>& dbs.log
