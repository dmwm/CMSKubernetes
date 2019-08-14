#!/bin/bash

# determine which port httpd server uses
aport=8280
suri="http://localhost:$aport/server-status/?auto"
echo "Start apache_exporter with $suri"
nohup apache_exporter -scrape_uri $suri -telemetry.address ":18280" 2>&1 1>& apache_exporter.log < /dev/null &

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
