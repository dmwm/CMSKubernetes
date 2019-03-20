#!/bin/bash

# start process exporter
pid=`ps axjfwww | grep "wmc-httpd.*reqmon" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=reqmgr2_exporter
address=":18246"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &
