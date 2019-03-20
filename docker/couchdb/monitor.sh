#!/bin/bash

# start couchdb exporter
nohup $GOPATH/bin/couchdb-prometheus-exporter 2>&1 1>& couchdb_exporter.log < /dev/null &
