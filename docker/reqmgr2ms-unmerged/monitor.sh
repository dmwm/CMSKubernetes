#!/bin/bash

conf="config-unmerged"
pat="wmc-httpd.*$conf"
pid=`ps axjfwww | grep "$pat" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
if [ -n "$pid" ]; then
    prefix=reqmgr2ms_exporter
    prefix=`echo $conf | sed -e "s,config-,ms_,g"`
    address=":18242"
    nohup process_exporter -pid $pid -prefix $prefix -address "$address" 2>&1 1>& ${prefix}.log < /dev/null &
fi

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
