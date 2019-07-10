#!/bin/bash

# start process exporter
nohup process_monitor.sh /data/srv/state/crabserver/pid crabserver ":18270" 15 2>&1 1>& ${prefix}.log < /dev/null &
