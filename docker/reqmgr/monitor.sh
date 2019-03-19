#!/bin/bash

# start process exporter
nohup process_monitor.sh "wmc-httpd -r -d /data/srv/state/reqmgr2" reqmgr2_exporter ":18246" 15 2>&1 1>& reqmgr2_exporter.log < /dev/null &

