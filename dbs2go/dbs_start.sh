#!/bin/bash
# start dbs2go server
cd $GOPATH/src/github.com/vkuznet/dbs2go
dbs2go -dbfile /tmp/dbs2go/dbfile.reader 2>&1 1>& dbs.log
