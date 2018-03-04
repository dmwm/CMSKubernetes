#!/bin/bash
# start dbs2go server
cd $GOPATH/src/github.com/vkuznet/dbs2go
dbs2go -config config_prod.json 2>&1 1>& dbs.log
