#!/bin/bash
cert=$1
if [ -n  "${AMURL}" ] ; then
    amurl=$AMURL
else
    amurl=http://cms-monitoring.cern.ch:30093
fi

while :
do
    certTime=`openssl x509 -enddate -noout -in $cert | sed -e "s,notAfter=,,g"`
    tstamp=`date --date="$certTime" +"%s"`
    now=`date +"%s"`
    if [ $tstamp -lt $now ] ; then
        msg="Certificate $cert expired on $certTime"
        echo $msg
        expire=`date -d '+5 min' --rfc-3339=ns | tr ' ' 'T'`
        if [ -f /data/amtool ] ; then
            /data/amtool alert add cert_alert \
                alertname=cert_alert severity=high tag=test alert=amtool \
                --end=$expire \
                --annotation=date="`date`" \
                --annotation=hostname="`hostname`" \
                --annotation=message="$msg" \
                --alertmanager.url=$amurl
        fi
    fi
    sleep 10
done
