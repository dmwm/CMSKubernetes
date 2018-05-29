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
    if [ -f /data/srv/current/auth/dbs/DBSSecrets.py ]; then
        /bin/rm -f /data/srv/current/auth/dbs/DBSSecrets.py
    fi
    cp /etc/secrets/DBSSecrets.py /data/srv/current/auth/dbs/DBSSecrets.py
fi

# overwrite proxy if it is present in /etc/secrets
if [ -f /etc/secrets/proxy ]; then
    mkdir -p /data/srv/state/dbs/proxy
    /bin/cp -f /etc/secrets/proxy /data/srv/state/dbs/proxy/proxy.cert
fi

# overwrite header-auth key file if it is present in /etc/secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
fi

# get proxy
/data/proxy.sh $USER
sleep 2

# start the service
/data/srv/current/config/dbs/manage setinstances 'I did read documentation'
/data/srv/current/config/dbs/manage start 'I did read documentation'

# start cron daemon
sudo /usr/sbin/crond -n
