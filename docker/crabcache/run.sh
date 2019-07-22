#!/bin/bash

# overwrite host PEM files in /data/srv area
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/srv/current/auth/crabcache/dmwm-service-key.pem
    sudo cp /etc/secrets/robotcert.pem /data/srv/current/auth/crabcache/dmwm-service-cert.pem
fi

# overwrite proxy file with one from secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/crabcache/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/crabcache/proxy/proxy.cert
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/crabcache
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

# start the service
/data/srv/current/config/crabcache/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
