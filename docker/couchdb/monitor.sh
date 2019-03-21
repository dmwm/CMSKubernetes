#!/bin/bash

# start couchdb exporter
nohup $GOPATH/bin/couchdb-prometheus-exporter -telemetry.address=":9984" 2>&1 1>& couchdb_exporter.log < /dev/null &
