#!/bin/bash

# overwrite host PEM files in /data/srv area
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/srv/current/auth/sitedb/dmwm-service-key.pem
    sudo cp /etc/secrets/robotcert.pem /data/srv/current/auth/sitedb/dmwm-service-cert.pem
fi

# overwrite proxy file with one from secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/sitedb/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/sitedb/proxy/proxy.cert
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    # generate new hmac key for couch
    chmod u+w /data/srv/current/auth/couchdb/hmackey.ini
    perl -e 'undef $/; print "[couch_cms_auth]\n"; print "hmac_secret = ", unpack("h*", <STDIN>), "\n"' < /etc/secrets/hmac > /data/srv/current/auth/couchdb/hmackey.ini
fi

# get proxy
/data/proxy.sh $USER
sleep 2

# start the service
/data/srv/current/config/sitedb/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
