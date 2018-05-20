#!/bin/bash

# overwrite host PEM files in /data/certs since we used them during installation time
if [ -f /etc/grid-security/hostkey.pem ]; then
    sudo cp /etc/grid-security/hostkey.pem /data/certs/
    sudo cp /etc/grid-security/hostcert.pem /data/certs/
fi

# overwrite proxy file with one from secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/couchdb/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/couchdb/proxy/proxy.cert
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

# adjust configuration for k8s
# VK temp fix: so far backend auth fails, but we'll trust our host auth
hostname=`hostname -f`
host=`host $hostname | awk '/has address/ { print $4 }'`
sed -i -e "s/{127.0.0.1, _admin, _admin}/{127.0.0.1, _admin, _admin},{$host, _admin, _admin}/g" /data/srv/current/config/couchdb/local.ini

# get proxy
sudo /data/proxy.sh $USER

# start the service
/data/srv/current/config/couchdb/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
