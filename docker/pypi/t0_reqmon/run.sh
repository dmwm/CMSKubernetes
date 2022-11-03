#!/bin/bash
# script to start t0_reqmon

STATEDIR=/data/state
LOGDIR=/data/logs
CFGFILE=/etc/secrets/config.py
mkdir -p /data/{logs,state}
wmc-httpd -r -d $STATEDIR -l "|rotatelogs $LOGDIR/t0_reqmon-%Y%m%d-`hostname -s`.log 86400" $CFGFILE
