#!/bin/bash

# overwrite host PEM files in /data/certs since we used them during installation time
if [ -f /etc/grid-security/hostkey.pem ]; then
#    sudo cp /etc/grid-security/hostkey.pem /data/certs/
#    sudo cp /etc/grid-security/hostcert.pem /data/certs/
    sudo cp /etc/grid-security/hostkey.pem /data/srv/current/auth/reqmgr2/dmwm-service-key.pem
    sudo cp /etc/grid-security/hostcert.pem /data/srv/current/auth/reqmgr2/dmwm-service-cert.pem
fi

# overwrite proxy file with one from secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/reqmgr2/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/reqmgr2/proxy/proxy.cert
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
fi

/data/srv/current/config/reqmgr2/manage start 'I did read documentation'
ps auxw | grep httpd
while true
do
    log=`ls -t /data/srv/logs/reqmgr2/reqmgr2*.log | head -1`
    tail -1 $log
    sleep 10
done
