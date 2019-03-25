#!/bin/bash

# start process exporter
pid=`ps axjfwww | grep "wmc-httpd.*confdb" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=confdb_exporter
address=":18340"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &
