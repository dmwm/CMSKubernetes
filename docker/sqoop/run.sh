#!/bin/bash

# Kerberos
keytab=/etc/cmsdb/keytab
principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
echo "principal=$principal"
kinit $principal -k -t "$keytab"
if [ $? == 1 ]; then
    echo "Unable to perform kinit"
    exit 1
fi
klist -k "$keytab"

# execute given script
export PATH=$PATH:/usr/hdp/hadoop/bin:/data:/data/sqoop
$@
if [ $? -ne 0 ]; then
    expire=`date -d '+2 hour' --rfc-3339=ns | tr ' ' 'T'`
    msg="Sqoop job failure"
    DATE=`date`
    host=`hostname`
    job=`echo $@`
    amhost="http://cms-monitoring.cern.ch:30093"
    amtool alert add sqoop_failure alertname='sqoop job failure' job="$job" host=$host severity=high tag=k8s alert=amtool kind=cluster service=sqoop --end=$expire --annotation=summary='$msg' --annotation=date='$DATE' --alertmanager.url=$amhost
    amhost="http://cms-monitoring-ha1.cern.ch:30093"
    amtool alert add sqoop_failure alertname='sqoop job failure' job="$job" host=$host severity=high tag=k8s alert=amtool kind=cluster service=sqoop --end=$expire --annotation=summary='$msg' --annotation=date='$DATE' --alertmanager.url=$amhost
    amhost="http://cms-monitoring-ha2.cern.ch:30093"
    amtool alert add sqoop_failure alertname='sqoop job failure' job="$job" host=$host severity=high tag=k8s alert=amtool kind=cluster service=sqoop --end=$expire --annotation=summary='$msg' --annotation=date='$DATE' --alertmanager.url=$amhost
fi
