#!/bin/bash

# overwrite host PEM files in /data/srv area
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/srv/current/auth/reqmon/dmwm-service-key.pem
    sudo cp /etc/secrets/robotcert.pem /data/srv/current/auth/reqmon/dmwm-service-cert.pem
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/reqmon/proxy
    ln -s /etc/proxy/proxy /data/srv/state/reqmon/proxy/proxy.cert
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
fi

# we need to populate reqmon dbs into couch first
if [ -f /data/srv/state/couchdb/stagingarea/reqmon ]; then
    arch=`ls /data/srv/current/sw | grep bootstrap | grep log | sed -e "s,bootstrap-,,g" -e "s,.log,,g"`
    ver=`ls /data/srv/current/sw/$arch/external/couchapp/ | tail -1`
    source /data/srv/current/sw/$arch/external/couchapp/$ver/etc/profile.d/init.sh
    source /data/srv/state/couchdb/stagingarea/reqmon
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/reqmon
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
/data/srv/current/config/reqmon/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
