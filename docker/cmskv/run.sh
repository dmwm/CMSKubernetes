#!/bin/sh
logDir=/data/logs/cmskv
if [ ! -d $logDir ]; then
    logDir=/data
fi
config=/data/config.json
if [ -f /etc/secrets/config.json ]; then
    config=/etc/secrets/config.json
fi

# start wmarchive process exporter
nohup /data/process_monitor.sh ".*config.json" cmskv_exporter ":18200" 15 2>&1 1>& $logDir/cmskv_exporter.log < /dev/null &
/data/cmskv -config=$config
