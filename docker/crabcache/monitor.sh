#!/bin/bash

# start process exporter for crabcache
pid=`ps axjfwww | grep "wmc-httpd.*crabcache" | grep -v grep | grep -v process_monitor | grep -v " 1 " | awk '{print $1}'`
prefix=crabcache_exporter
address=":18271"
nohup process_exporter -pid $pid -prefix $prefix -address $address 2>&1 1>& ${prefix}.log < /dev/null &
