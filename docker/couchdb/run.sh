#!/bin/bash

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/reqmgr2/proxy
    ln -s /etc/proxy/proxy /data/srv/state/reqmgr2/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    # generate new hmac key for couch
    chmod u+w /data/srv/current/auth/couchdb/hmackey.ini
    perl -e 'undef $/; print "[couch_cms_auth]\n"; print "hmac_secret = ", unpack("h*", <STDIN>), "\n"' < /etc/secrets/hmac > /data/srv/current/auth/couchdb/hmackey.ini
    chmod ug+rx,o-rwx /data/srv/current/auth/couchdb/hmackey.ini
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/couchdb
files=`ls $cdir`
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $cdir/$fname ]; then
            rm $cdir/$fname
        fi
        ln -s /etc/secrets/$fname $cdir/$fname
    fi
done

# start the service
/data/srv/current/config/couchdb/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
