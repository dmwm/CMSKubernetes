#!/bin/bash

# overwrite DBSSecrerts if it is present in /etc/secrets
if [ -f /etc/secrets/DBSSecrets.py ]; then
    if [ -f /data/srv/current/auth/dbs/DBSSecrets.py ]; then
        /bin/rm -f /data/srv/current/auth/dbs/DBSSecrets.py
    fi
    cp /etc/secrets/DBSSecrets.py /data/srv/current/auth/dbs/DBSSecrets.py
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/dbs/proxy
    ln -s /etc/proxy/proxy /data/srv/state/dbs/proxy/proxy.cert
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
if [ -f /etc/tnsnames.ora ] && [ -f $tfile ]; then
    rm $tfile
    ln -s /etc/tnsnames.ora $tfile
fi

# start the service
/data/srv/current/config/dbs/manage setinstances 'I did read documentation'
/data/srv/current/config/dbs/manage start 'I did read documentation'

# place test request to DBS
port=`grep ^config.Webtools.port /data/srv/current/config/dbs/DBSGlobalReader.py | awk '{split($0,a,"="); print a[2]}' | sed -e "s, ,,g"`
inst=`grep ^VARIAN /data/srv/current/config/dbs/DBSGlobalReader.py | awk '{split($0,a,"="); print a[2]}' | sed -e "s, ,,g" -e "s,\",,g"`
if [ "$inst" == "default" ]; then
    inst="dev"
fi
echo "We can test DBS from local host as following:"
echo "curl -v -H "cms-auth-status":"NONE" http://localhost:$port/dbs/$inst/global/DBSReader/datatiers?data_tier_name=RAW"

# use service configuration files from /etc/secrets if they are present 
cdir=/data/srv/current/config/dbs
files=`ls $cdir`
# check if /etc/secrets area contain at least one dbs configuration files
cfiles="DBSDef.py DBSMigrate.py DBSGlobalReader.py DBSGlobalWriter.py DBSPhys03Reader.py DBSPhys03Writer.py"
for fname in $cfiles; do
    if [ -f /etc/secrets/$fname ]; then
        # we'll remove all conf files and create a link later
        cd $cdir
        rm $cfiles
        cd -
        break
    fi
done
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $cdir/$fname ]; then
            rm $cdir/$fname
        fi
        sudo cp /etc/secrets/$fname $cdir/$fname
        sudo chown $USER.$USER $cdir/$fname
    fi
done

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# start cron daemon
sudo /usr/sbin/crond -n
