#!/bin/bash
# script to start workqueue

STATEDIR=/data/state
LOGDIR=/data/logs
CFGFILE=/etc/secrets/config.py
mkdir -p /data/{logs,state}
wmc-httpd -r -d $STATEDIR -l "|rotatelogs $LOGDIR/workqueue-%Y%m%d-`hostname -s`.log 86400" $CFGFILE
