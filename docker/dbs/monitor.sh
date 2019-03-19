#!/bin/bash

# start process exporter
nohup process_monitor.sh ".*DBSGlobalReader" dbs_global_exporter ":18250" 15 2>&1 1>& dbs_global_exporter.log < /dev/null &

