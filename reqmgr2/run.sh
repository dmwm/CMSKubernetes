#!/bin/bash
if [ -f /etc/grid-security/hostkey.pem ]; then
    # overwrite host PEM files in /data/certs since we used them during installation time
    sudo cp /etc/grid-security/hostkey.pem /data/certs/
    sudo cp /etc/grid-security/hostcert.pem /data/certs/
    /data/cfg/admin/InstallDev -s start
    ps auxw | grep httpd
    while true
    do
        log=`ls -t /data/srv/logs/reqmgr2/access_log* | head -1`
        tail -1 $log
        sleep 1
    done
else
    echo "Unable to start frontend, host PEM files are not found"
fi
