#!/bin/bash

# start process exporters
nohup process_monitor.sh /data/srv/state/reqmgr2/pid reqmgr2 ":18240" 15 2>&1 1>& ${prefix}.log < /dev/null &
