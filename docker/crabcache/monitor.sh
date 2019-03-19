#!/bin/bash

# start process exporter
nohup process_monitor.sh ".*crabcache/config.py" crabcache_exporter ":18271" 15 2>&1 1>& crabcache_exporter.log < /dev/null &

