#!/bin/bash

expire=`date -d '+2 hour' --rfc-3339=ns | tr ' ' 'T'`
msg="Frontend cronjob failure"
DATE=`date`
host=`hostname`
job="frontendx509"
amhost="http://cms-monitoring.cern.ch:30093"
amtool alert add frontendx509_cronjob_failure alertname='Frontend cronjob failure' job="$job" host="$host" tag=cmsweb alert=amtool service=cron --end="$expire" --annotation=summary="$msg" --annotation=date="$DATE" --alertmanager.url="$amhost" action=restart
amhost="http://cms-monitoring-ha1.cern.ch:30093"
amtool alert add frontendx509_cronjob_failure alertname='Frontend cronjob failure' job="$job" host="$host" tag=cmsweb alert=amtool service=cron --end="$expire" --annotation=summary="$msg" --annotation=date="$DATE" --alertmanager.url="$amhost" action=restart
amhost="http://cms-monitoring-ha2.cern.ch:30093"
amtool alert add frontendx509_cronjob_failure alertname='Frontend cronjob failure' job="$job" host="$host" tag=cmsweb alert=amtool service=cron --end="$expire" --annotation=summary="$msg" --annotation=date="$DATE" --alertmanager.url="$amhost" action=restart
