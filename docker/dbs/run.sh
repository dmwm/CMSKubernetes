#!/bin/bash
#cd /data/srv
#verb=start; for f in enabled/*; do
#  app=${f#*/}; case $app in frontend) u=root ;; * ) u=_$app ;; esac; sh -c \
#  "$PWD/current/config/$app/manage $verb 'I did read documentation'"
#  if [ "$app" == "dbs" ] || [ "$app" == "dbsmigration" ]; then
#    sh -c "$PWD/current/config/$app/manage setinstances 'I did read documentation'"
#  fi
#done

if [ -f /etc/secrets/DBSSecrets.py ]; then
    if [ -f /data/srv/current/auth/dbs/DBSSecrets.py ]; then
        /bin/rm -f /data/srv/current/auth/dbs/DBSSecrets.py
    fi
    cp /etc/secrets/DBSSecrets.py /data/srv/current/auth/dbs/DBSSecrets.py
fi
sh -c "/data/srv/current/config/dbs/manage setinstances 'I did read documentation'"
sh -c "/data/srv/current/config/dbs/manage start 'I did read documentation'"
while true;
do
    msg=`curl http://localhost:8252/dbs | grep Welcome`
    cat $msg
    sleep 10
done
