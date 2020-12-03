#!/bin/bash

# start process exporters
process_monitor.sh ".*dbs2go" dbs2go_exporter ":18258" 15 2>&1 1>& dbs2go_exporter.log &

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
