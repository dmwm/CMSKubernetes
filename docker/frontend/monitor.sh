#!/bin/bash

# determine which port httpd server uses
aport=`cat /data/srv/state/frontend/server.conf | grep Listen | grep 80 | awk '{print $2}'`
suri="http://localhost:$aport/server-status/?auto"
echo "Start apache_exporter with $suri"
nohup apache_exporter --scrape_uri $suri --telemetry.address ":18443" 2>&1 1>& apache_exporter.log < /dev/null &

cat > /data/filebeat.conf << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /data/srv/logs/frontend/access_log_`hostname -s`*.txt
  scan_frequency: 10s
  backoff: 5s
  max_backoff: 10s
  tags: ["frontend"]
output.logstash:
    hosts: ["logstash.monitoring:5044"]
#output.file:
#  path: "/tmp/filebeat"
#  filename: filebeat
#output.console:
#  pretty: true
EOF

# run filebeat
if [ -f /data/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /data/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
