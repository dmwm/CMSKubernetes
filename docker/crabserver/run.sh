#!/bin/bash

# overwrite host PEM files in /data/srv area
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/srv/current/auth/crabserver/dmwm-service-key.pem
    sudo cp /etc/secrets/robotcert.pem /data/srv/current/auth/crabserver/dmwm-service-cert.pem
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/crabserver/proxy
    ln -s /etc/proxy/proxy /data/srv/state/crabserver/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/crabserver
files=`ls $cdir`
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $cdir/$fname ]; then
            rm $cdir/$fname
        fi
        sudo cp /etc/secrets/$fname $cdir/$fname
        sudo chown $USER.$USER $cdir/$fname
    fi
done

# add t0auth.py
if [ -f /etc/secrets/CRABServerAuth.py ]; then
    sudo rm /data/srv/current/auth/crabserver/CRABServerAuth.py
    ln -s /etc/secrets/CRABServerAuth.py /data/srv/current/auth/crabserver/CRABServerAuth.py
fi

# start the service
/data/srv/current/config/crabserver/manage start 'I did read documentation'

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# start cron daemon
sudo /usr/sbin/crond -n
