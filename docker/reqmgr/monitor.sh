#!/bin/bash

# start process exporter
#nohup process_monitor.sh ".*wmc-httpd.*reqmgr2.*" reqmgr2_exporter ":18246" 15 2>&1 1>& reqmgr2_exporter.log < /dev/null &
pid=`ps axjfwww | grep "wmc-httpd.*reqmgr2" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=reqmgr2_exporter
address=":18246"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &
