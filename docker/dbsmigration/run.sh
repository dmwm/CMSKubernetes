#!/bin/bash

# overwrite DBSSecrerts if it is present in /etc/secrets
if [ -f /etc/secrets/DBSSecrets.py ]; then
    if [ -f /data/srv/current/auth/dbsmigration/DBSSecrets.py ]; then
        /bin/rm -f /data/srv/current/auth/dbsmigration/DBSSecrets.py
    fi
    cp /etc/secrets/DBSSecrets.py /data/srv/current/auth/dbsmigration/DBSSecrets.py
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/dbsmigration/proxy
    ln -s /etc/proxy/proxy /data/srv/state/dbsmigration/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# overwrite header-auth key file if it is present in /etc/secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
fi

# get fresh copy of tnsnames.ora from secrets or local area
tfile=`find /data/srv/current/sw/ -name tnsnames.ora`
if [ -f /etc/secrets/tnsnames.ora ] && [ -f $tfile ]; then
    /bin/cp -f /etc/secrets/tnsnames.ora $tfile
elif [ -f /data/tnsnames.ora ] && [ -f $tfile ]; then
    /bin/cp -f /data/tnsnames.ora $tfile
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/dbsmigration
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
/data/srv/current/config/dbsmigration/manage setinstances 'I did read documentation'
/data/srv/current/config/dbsmigration/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
