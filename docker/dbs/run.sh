#!/bin/bash
srv=`echo $USER | sed -e "s,_,,g"`

# overwrite host PEM files in /data/srv area
if [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/srv/current/auth/$srv/dmwm-service-key.pem
    sudo cp /etc/secrets/robotcert.pem /data/srv/current/auth/$srv/dmwm-service-cert.pem
    sudo chown $USER.$USER /data/srv/current/auth/$srv/dmwm-service-key.pem
    sudo chown $USER.$USER /data/srv/current/auth/$srv/dmwm-service-cert.pem
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/$srv/proxy
    cp /etc/proxy/proxy /data/srv/state/$srv/proxy/proxy.cert
    sudo chown $USER.$USER /data/srv/state/$srv/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    cp /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
    sudo chown $USER.$USER /data/srv/current/auth/proxy/proxy
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    if [ -f /data/srv/current/auth/wmcore-auth/header-auth-key ]; then
        sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
        cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
        sudo chown $USER.$USER /data/srv/current/auth/wmcore-auth/header-auth-key
    fi
    if [ -f /data/srv/current/auth/$srv/header-auth-key ]; then
        sudo rm /data/srv/current/auth/$srv/header-auth-key
        cp /etc/secrets/hmac /data/srv/current/auth/$srv/header-auth-key
        sudo chown $USER.$USER /data/srv/current/auth/$srv/header-auth-key
    fi
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/$srv
# check if /etc/secrets area contain at least one dbs configuration files
cfiles="DBSDef.py DBSMigrate.py DBSGlobalReader.py DBSGlobalWriter.py DBSPhys03Reader.py DBSPhys03Writer.py"
for fname in $cfiles; do
    if [ -f /etc/secrets/$fname ]; then
        cd $cdir
        rm $cfiles
        cd -
    fi
    if [ -f /etc/secrets/$fname ]; then
        sudo cp /etc/secrets/$fname $cdir/$fname
        sudo chown $USER.$USER $cdir/$fname
    fi
done
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
files=`ls /etc/secrets`
for fname in $files; do
    if [ ! -f $cdir/$fname ]; then
        sudo cp /etc/secrets/$fname /data/srv/current/auth/$srv/$fname
        sudo chown $USER.$USER /data/srv/current/auth/$srv/$fname
    fi
done

# get fresh copy of tnsnames.ora from secrets or local area
tfile=`find /data/srv/current/sw/ -name tnsnames.ora`
if [ -f /etc/tnsnames.ora ] && [ -f $tfile ] && [ -n "$tfile" ]; then
    rm $tfile
    ln -s /etc/tnsnames.ora $tfile
fi


# start the service
/data/srv/current/config/$srv/manage setinstances 'I did read documentation'
/data/srv/current/config/$srv/manage start 'I did read documentation'

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# start cron daemon
sudo /usr/sbin/crond -n
