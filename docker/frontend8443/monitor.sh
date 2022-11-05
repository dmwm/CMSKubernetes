#!/bin/bash

# determine which port httpd server uses
aport=`cat /data/srv/state/frontend8443/server.conf | grep Listen | grep 80 | awk '{print $2}'`
suri="http://localhost:$aport/server-status/?auto"
echo "Start apache_exporter with $suri"
nohup apache_exporter --scrape_uri $suri --telemetry.address ":18443" 2>&1 1>& apache_exporter.log < /dev/null &

NAME=`hostname -s`
if [ -n $MY_POD_NAME ]; then
    NAME=$MY_POD_NAME
fi


cat > /data/filebeat.yaml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /data/srv/logs/frontend8443/access_log_${NAME}*.txt
  file_identity.path:
  scan_frequency: 10s
  backoff: 5s
  max_backoff: 10s
  tags: ["frontend8443"]
# disable internal monitoring, uncomment line below, default is true
# logging.metrics.enabled: false
# change loggin metrics interval, when logging.metrics is enabled
# logging.metrics.period: 30s
output.logstash:
  hosts: ["logstash.monitoring:5044"]
  compression_level: 3
  worker: 4
  bulk_max_size: 4096
  pipelining: 2
#output.file:
#  path: "/tmp/filebeat"
#  filename: filebeat
#output.console:
#  pretty: true
queue.mem:
  events: 65536
EOF

# run filebeat
if [ -f /data/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    if [ -d /data/filebeat/${NAME} ] && [ -f /data/filebeat/${NAME}/data/filebeat.lock ]; then
       rm /data/filebeat/${NAME}/data/filebeat.lock
    fi
    ldir=/data/filebeat/${NAME}
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /data/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
