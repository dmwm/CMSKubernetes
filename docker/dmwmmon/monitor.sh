#!/bin/bash

# determine which port httpd server uses
aport=8280
suri="http://localhost:$aport/server-status/?auto"
echo "Start apache_exporter with $suri"
nohup apache_exporter -scrape_uri $suri -telemetry.address ":18280" 2>&1 1>& apache_exporter.log < /dev/null &
