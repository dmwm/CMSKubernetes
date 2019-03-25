#!/bin/bash

# start process exporter
pid=`ps axjfwww | grep "wmc-httpd.*dmwmmon" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=dmwmmon_exporter
address=":18280"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &
