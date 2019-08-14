#!/bin/bash
# start das exporters
nohup das2go_exporter -address ":18217" 2>&1 1>& das2go_exporter.log < /dev/null &
# we need to build first mongodb_exporter
nohup mongodb_exporter -mongodb.uri mongodb://localhost:8230 --web.listen-address ":18230" 2>&1 1>& mongo_exporter.log < /dev/null &

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
