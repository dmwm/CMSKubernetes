#!/bin/bash
if [ -f /etc/grid-security/hostkey.pem ]; then
    # overwrite host PEM files in /data/certs since we used them during installation time
    sudo cp /etc/grid-security/hostkey.pem /data/certs/
    sudo cp /etc/grid-security/hostcert.pem /data/certs/
fi
/data/srv/current/config/reqmgr2/manage start 'I did read documentation'
ps auxw | grep httpd
while true
do
    log=`ls -t /data/srv/logs/reqmgr2/reqmgr2*.log | head -1`
    tail -1 $log
    sleep 1
done
