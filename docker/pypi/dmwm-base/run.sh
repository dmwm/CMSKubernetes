#!/bin/bash
# script to start ReqMgr2

srv=`echo $USER | sed -e "s,_,,g"`
STATEDIR=/data/srv/state/$srv
LOGDIR=/data/srv/logs/$srv
AUTHDIR=/data/srv/current/auth/$srv
CONFIGDIR=/data/srv/current/config/$srv
CONFIGFILE=${CONFIGFILE:-config.py}
CFGFILE=/etc/secrets/$CONFIGFILE

mkdir -p $LOGDIR
mkdir -p $STATEDIR
mkdir -p $AUTHDIR
mkdir -p $CONFIGDIR
mkdir -p $AUTHDIR/proxy
mkdir -p $AUTHDIR/../wmcore-auth

# environment variables required to run some of the WMCore services
export REQMGR_CACHE_DIR=$STATEDIR
export WMCORE_CACHE_DIR=$STATEDIR

# overwrite host PEM files in /data/srv area
if [ -f /etc/robots/robotkey.pem ]; then
    sudo cp /etc/robots/robotkey.pem $AUTHDIR/dmwm-service-key.pem
    sudo cp /etc/robots/robotcert.pem $AUTHDIR/dmwm-service-cert.pem
    sudo chown $USER.$USER $AUTHDIR/dmwm-service-key.pem
    sudo chown $USER.$USER $AUTHDIR/dmwm-service-cert.pem
    sudo chmod 0400 $AUTHDIR/dmwm-service-key.pem
fi

if [ -e $AUTHDIR/dmwm-service-cert.pem ] && [ -e $AUTHDIR/dmwm-service-key.pem ]; then
    export X509_USER_CERT=$AUTHDIR/dmwm-service-cert.pem
    export X509_USER_KEY=$AUTHDIR/dmwm-service-key.pem
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    sudo cp /etc/proxy/proxy $AUTHDIR/proxy/proxy
    export X509_USER_PROXY=$AUTHDIR/proxy/proxy
fi

# overwrite header-auth key file with one from secrets

if [ -f /etc/hmac/hmac ]; then
    if [ -f $AUTHDIR/../header-auth-key ]; then
        sudo rm $AUTHDIR/../header-auth-key
    fi
    sudo cp /etc/hmac/hmac $AUTHDIR/../wmcore-auth/header-auth-key
    sudo chown $USER.$USER $AUTHDIR/../wmcore-auth/header-auth-key

    if [ -f $AUTHDIR/header-auth-key ]; then
        sudo rm $AUTHDIR/header-auth-key
    fi
    sudo cp /etc/hmac/hmac $AUTHDIR/header-auth-key
    sudo chown $USER.$USER $AUTHDIR/header-auth-key
    # why do we need this hmac file at /auth directory as well?
    sudo mkdir -p /auth/wmcore-auth
    sudo ln -s /data/srv/current/auth/$srv/header-auth-key /auth/wmcore-auth/header-auth-key
fi

# use service configuration files from /etc/secrets if they are present
files=`ls /etc/secrets`
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $CONFIGDIR/$fname ]; then
            rm $CONFIGDIR/$fname
        fi
        sudo cp /etc/secrets/$fname $CONFIGDIR/$fname
        sudo chown $USER.$USER $CONFIGDIR/$fname
        if [ "$fname" == "$CONFIGFILE" ]; then
            CFGFILE=$CONFIGDIR/$CONFIGFILE
        fi
    fi
done
files=`ls /etc/secrets`
for fname in $files; do
    if [ ! -f $CONFIGDIR/$fname ]; then
        sudo cp /etc/secrets/$fname $AUTHDIR/$fname
        sudo chown $USER.$USER $AUTHDIR/$fname
    fi
done

export PYTHONPATH=$PYTHONPATH:/etc/secrets:$AUTHDIR/$fname

# start the service
wmc-httpd -r -d $STATEDIR -l "|rotatelogs $LOGDIR/$srv-%Y%m%d-`hostname -s`.log 86400" $CFGFILE
