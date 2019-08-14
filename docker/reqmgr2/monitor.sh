#!/bin/bash

# start process exporters
nohup process_monitor.sh /data/srv/state/reqmgr2/pid reqmgr2 ":18240" 15 2>&1 1>& reqmgr2_monitor.log < /dev/null &

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
