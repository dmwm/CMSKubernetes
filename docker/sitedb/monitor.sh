#!/bin/bash

# start process exporter
pid=`ps axjfwww | grep "wmc-httpd.*sitedb" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=sitedb_exporter
address=":18051"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
