#!/bin/bash
srv=$(echo $USER | sed -e "s,_,,g")

if [ -f /etc/secrets/couch_creds ]; then
    export COUCH_CREDS=/etc/secrets/couch_creds
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    mkdir -p /data/srv/current/auth/wmcore-auth
    if [ -f /data/srv/current/auth/wmcore-auth/header-auth-key ]; then
        sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    fi
    sudo cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    sudo chown $USER.$USER /data/srv/current/auth/wmcore-auth/header-auth-key
    mkdir -p /data/srv/current/auth/$srv
    if [ -f /data/srv/current/auth/$srv/header-auth-key ]; then
        sudo rm /data/srv/current/auth/$srv/header-auth-key
    fi
    sudo cp /etc/secrets/hmac /data/srv/current/auth/$srv/header-auth-key
    sudo chown $USER.$USER /data/srv/current/auth/$srv/header-auth-key

    # generate new hmac key for couch
    chmod u+w /data/srv/current/auth/$srv/hmackey.ini
    perl -e 'undef $/; print "[couch_cms_auth]\n"; print "hmac_secret = ", unpack("h*", <STDIN>), "\n"' \
        < /data/srv/current/auth/wmcore-auth/header-auth-key \
        > /data/srv/current/auth/$srv/hmackey.ini
    chmod ug+rx,o-rwx /data/srv/current/auth/$srv/hmackey.ini
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/$srv
files=$(ls $cdir)
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $cdir/$fname ]; then
            rm $cdir/$fname
        fi
        sudo cp /etc/secrets/$fname $cdir/$fname
        sudo chown $USER.$USER $cdir/$fname
    fi
done
files=$(ls /etc/secrets)
for fname in $files; do
    if [ ! -f $cdir/$fname ]; then
        sudo cp /etc/secrets/$fname /data/srv/current/auth/$srv/$fname
        sudo chown $USER.$USER /data/srv/current/auth/$srv/$fname
    fi
done

if [ -f /data/srv/current/auth/$srv/couch_creds ]; then
    # also create the ini configuration for prometheus exporter
    cp /data/srv/current/auth/$srv/couch_creds /data/srv/current/auth/$srv/couchdb_config.ini
    sed -i "s+COUCH_USER+couchdb.username+" /data/srv/current/auth/$srv/couchdb_config.ini
    sed -i "s+COUCH_PASS+couchdb.password+" /data/srv/current/auth/$srv/couchdb_config.ini
else
  # create empty file
  echo "ERROR: couch_creds file has not been found and prometheus exporter cannot run!"
  touch /data/srv/current/auth/$srv/couchdb_config.ini
fi


# start the service
/data/srv/current/config/$srv/manage start 'I did read documentation'

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# start cron daemon
#sudo /usr/sbin/crond -n
tail -f /data/srv/logs/couchdb/couch.log
