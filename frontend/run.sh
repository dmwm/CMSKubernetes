#!/bin/bash
# obtain CERN CAs if they're not present
#n=`ls /etc/pki/tls/private/*.key 2> /dev/null | wc -c`
#if [ "$n" -eq "0" ]; then
#    sudo /usr/sbin/cern-get-certificate --autoenroll
#    ckey=`ls /etc/pki/tls/private/*.key | tail -1`
#    host=`basename $ckey | sed -e "s,.key,,g"`
#    cert=`ls /etc/pki/tls/certs/$host.pem`
#    sudo cp $ckey /data/certs/hostkey.pem
#    sudo cp $cert /data/certs/hostcert.pem
#fi
if [ -f /etc/grid-security/hostkey.pem ]; then
    # overwrite host PEM files in /data/certs since we used them during installation time
    sudo cp /etc/grid-security/hostkey.pem /data/certs/
    sudo cp /etc/grid-security/hostcert.pem /data/certs/
    /data/cfg/admin/InstallDev -s start
    ps auxw | grep httpd
    while true
    do
        log=`ls -t /data/srv/logs/frontend/access_log* | head -1`
        tail -1 $log
        sleep 1
    done
else
    echo "Unable to start frontend, host PEM files are not found"
fi
