#!/bin/bash

# start process exporter
nohup process_monitor.sh ".*wmc-httpd.*crabserver.*" crabserver_exporter ":18270" 15 2>&1 1>& crabserver_exporter.log < /dev/null &

