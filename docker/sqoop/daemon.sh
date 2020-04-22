#!/bin/bash

wdir=$1
interval=$2

if [ "$wdir" == "" ]; then
    wdir=/data/sqoop
fi
if [ "$interval" == "" ]; then
    interval=3600
fi
echo "daemon: $wdir with interval=$interval"
if [ -d $wdir ]; then
    cd $wdir
fi

# run daemon
while true; do
   rm -f $wdir/log/*
   $wdir/run.sh $wdir/cms-dbs3-datasets.sh
   $wdir/run.sh $wdir/cms-dbs3-blocks.sh
   $wdir/run.sh $wdir/cms-dbs3-files.sh
   sleep $interval
done
