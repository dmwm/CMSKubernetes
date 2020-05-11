#!/bin/bash
# clean-up log daemon

wdir=$1
mtime=$2
interval=$3

if [ "$wdir" == "" ]; then
    wdir=/data/sqoop/log # default directory to look
fi
if [ "$mtime" == "" ]; then
    mtime=7 # default modification time to find
fi
if [ "$interval" == "" ]; then
    interval=3600 # default sleep interval
fi
echo "daemon: $wdir with interval=$interval, mtime=$mtime"

# start crond if it is not run
if [ -z "`ps auxww | grep crond | grep -v grep`" ]; then
    crond -n &
fi

# run daemon
while true; do
    files=`find $wdir -mtime +$mtime`
    for f in $files; do
        if [ -f $f ] && [ ! -d $f ]; then
            echo "delete: $f"
        fi
    done
    sleep $interval
done
