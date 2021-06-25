#!/bin/bash

# start process exporter
for p in "config-monitor" "config-output" "config-transferor" "config-ruleCleaner"; do
    pat="wmc-httpd.*$p"
    pid=`ps axjfwww | grep "$pat" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
    if [ -n "$pid" ]; then
        prefix=reqmgr2ms_exporter
        prefix=`echo $p | sed -e "s,config-,ms_,g"`
        if [ "$p" == "config-monitor" ]; then
            address=":18248"
        fi
        if [ "$p" == "config-output" ]; then
            address=":18245"
        fi
        if [ "$p" == "config-transferor" ]; then
            address=":18247"
        fi
        if [ "$p" == "config-ruleCleaner" ]; then
            address=":18244"
        fi
        nohup process_exporter -pid $pid -prefix $prefix -address "$address" 2>&1 1>& ${prefix}.log < /dev/null &
    fi
done

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
