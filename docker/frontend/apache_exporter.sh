#!/bin/bash

# determine which port httpd server uses
aport=`cat /data/srv/state/frontend/server.conf | grep Listen | grep 80 | awk '{print $2}'`
suri="http://localhost:$aport/server-status/?auto"
echo "Start apache_exporter with $suri"
nohup apache_exporter -scrape_uri $suri -telemetry.address ":18443" 2>&1 1>& apache_exporter.log < /dev/null &
