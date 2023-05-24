#!/bin/bash

echo -e "\nTrying to start process_exporter..."
# start process exporter
configs="config config-monitor config-output config-transferor config-ruleCleaner config-unmerged"
for p in $configs; do
    if [ -f /etc/secrets/${p}.py ]; then
        echo "  Using configuration file: /etc/secrets/${p}.py"
        pat="wmc-httpd.*$p"
        pid=`ps axjfwww | grep "$pat" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
        if [ -n "$pid" ]; then
            app=`grep ^main.application /etc/secrets/${p}.py | grep -v application_dir | sed -e 's,#.*,,g' | awk '{split($0,a,"="); print a[2]}' | sed -e "s, ,,g" -e 's,",,g' -e "s,-,_,g"`
            echo "  Using PID: $pid and app name: '$app'"
            if [ -n "$app" ]; then
                prefix=${app}
                port=`grep main.port /etc/secrets/${p}.py | sed -e 's,#.*,,g' | awk '{split($0,a,"="); print a[2]}' | sed -e "s, ,,g"`
                address=":1${port}"
                echo "  Starting process_exporter with prefix ${prefix} on ${address}"
                nohup process_exporter -pid $pid -prefix $prefix -address "$address" 2>&1 1>& ${prefix}.log < /dev/null &
                #cpyAddr=`echo ${address} | sed "s,8,9,g"`
                #echo "Start cpy_exporter on ${cpyAddr}"
                #nohup cpy_exporter -address "$address" 2>&1 1>& cpy_${prefix}.log < /dev/null &
            fi
        fi
    fi
done
