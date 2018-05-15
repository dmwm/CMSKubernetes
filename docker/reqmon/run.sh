#!/bin/bash

# overwrite host PEM files in /data/srv area
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/srv/current/auth/reqmon/dmwm-service-key.pem
    sudo cp /etc/secrets/robotcert.pem /data/srv/current/auth/reqmon/dmwm-service-cert.pem
fi

# overwrite proxy file with one from secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/reqmon/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/reqmon/proxy/proxy.cert
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

# start the service
/data/srv/current/config/reqmon/manage start 'I did read documentation'

# start infinitive loop to show that we run the service
# since we're dealing with logs rotation we'll inspect them manually
while true
do
    sleep 10
done
