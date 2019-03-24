#!/bin/bash
#cd /data/srv
#verb=start; for f in enabled/*; do
#  app=${f#*/}; case $app in frontend) u=root ;; * ) u=_$app ;; esac; sh -c \
#  "$PWD/current/config/$app/manage $verb 'I did read documentation'"
#  if [ "$app" == "dbs" ] || [ "$app" == "dbsmigration" ]; then
#    sh -c "$PWD/current/config/$app/manage setinstances 'I did read documentation'"
#  fi
#done

# overwrite DBSSecrerts if it is present in /etc/secrets
if [ -f /etc/secrets/DBSSecrets.py ]; then
    if [ -f /data/srv/current/auth/dbsmigration/DBSSecrets.py ]; then
        /bin/rm -f /data/srv/current/auth/dbsmigration/DBSSecrets.py
    fi
    cp /etc/secrets/DBSSecrets.py /data/srv/current/auth/dbsmigration/DBSSecrets.py
fi

# overwrite proxy if it is present in /etc/secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/dbsmigration/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/dbsmigration/proxy/proxy.cert
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

# get proxy
/data/proxy.sh $USER
sleep 2

# start the service
/data/srv/current/config/dbsmigration/manage setinstances 'I did read documentation'
/data/srv/current/config/dbsmigration/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
