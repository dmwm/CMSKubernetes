#!/bin/bash

# start process exporter
pid=`ps axjfwww | grep "phedex-web.py" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=phedex_exporter
address=":17001"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &
