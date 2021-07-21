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
nohup /data/wmarchive -config=$config
