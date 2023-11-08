#!/bin/bash

expire=`date -d '+2 hour' --rfc-3339=ns | tr ' ' 'T'`
msg="MongoDB backup cronjob failure"
DATE=`date`
host=`hostname`
job="mongodb"
tag="cmsweb"
amhost="http://cms-monitoring-ha1.cern.ch:30093"
amtool alert add mongodb_cronjob_failure alertname="$msg" tag="$tag" job="$job" host="$host" alert=amtool service=cron --end="$expire" --annotation=summary="$msg" --annotation=date="$DATE" --alertmanager.url="$amhost" action=restart
amhost="http://cms-monitoring-ha1.cern.ch:30093"
