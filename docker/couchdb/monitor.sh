#!/bin/bash

# start couchdb exporter
nohup $GOPATH/bin/couchdb-prometheus-exporter -telemetry.address=":9984" 2>&1 1>& couchdb_exporter.log < /dev/null &

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
