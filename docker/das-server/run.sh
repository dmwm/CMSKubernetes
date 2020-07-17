#!/bin/sh
mkdir -p /data/logs
nohup /data/das2go_exporter -address ":18217" 2>&1 1>& /data/logs/das2go_exporter.log < /dev/null &
/data/das2go -config /etc/secrets/dasconfig.json
