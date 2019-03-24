#!/bin/bash

# start process exporter
nohup process_monitor.sh ".*dbsmigration" dbsmigration ":18251" 15 2>&1 1>& dbsmigration.log < /dev/null &
