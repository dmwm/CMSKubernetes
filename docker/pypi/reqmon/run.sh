#!/bin/bash
# script to start reqmon

STATEDIR=/data/state
LOGDIR=/data/logs
CFGFILE=/etc/secrets/config.py
mkdir -p /data/{logs,state}
wmc-httpd -r -d $STATEDIR -l "|rotatelogs $LOGDIR/reqmon-%Y%m%d-`hostname -s`.log 86400" $CFGFILE
