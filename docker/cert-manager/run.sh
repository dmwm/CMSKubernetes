#!/bin/bash
cert_path=$1
if [ -n  "${AMURL}" ] ; then
    amurl=$AMURL
else
    amurl=http://cms-monitoring.cern.ch:30093
fi

while :
do
    for cert in "$cert_path"/*; do
        certTime=`openssl x509 -enddate -noout -in $cert | sed -e "s,notAfter=,,g"`
        tstamp=`date --date="$certTime" +"%s"`
        alertDate=`date -d "+15 days" +"%s"`
        if [  ! -z  "$certTime" ] && [ $tstamp -lt $alertDate ] ; then
            msg="Certificate $cert on pod $POD_NAME running on node $NODE_NAME will expire on $certTime"
            expire=`date -d '+15 days' --rfc-3339=ns | tr ' ' 'T'`
            if [ -f /data/amtool ] ; then
                /data/amtool alert add cert_alert \
                    alertname=cert_alert severity=high tag=cmsweb alert=amtool \
                    --end=$expire \
                    --annotation=date="`date`" \
                    --annotation=hostname="`hostname`" \
                    --annotation=message="$msg" \
                    --alertmanager.url=$amurl
            fi
        fi
    done
    sleep 10
done
