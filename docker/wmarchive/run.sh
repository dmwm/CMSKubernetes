#!/bin/sh
logDir=/data/srv/logs/wma
if [ ! -d $logDir ]; then
    logDir=/data
fi
config=/data/wmarch_go.json
if [ -f /etc/secrets/wmarch_go.json ]; then
    config=/etc/secrets/wmarch_go.json
fi

# start wmarchive process exporter
#nohup /data/process_monitor.sh ".*wmarch_go.json" wma_exporter ":18200" 15 2>&1 1>& $logDir/wma_exporter.log < /dev/null &
nohup /data/wmarchive -config=$config
