#!/bin/bash
# get proxy
echo "USER=$USER"
sudo /data/proxy.sh $USER
# start dbs2go server
cd $GOPATH/src/github.com/vkuznet/dbs2go
if [ -f /etc/secrets/dbsconfig.json ]; then
    sudo cp /etc/secrets/dbfile /data/srv/current/auth/proxy/dbfile
    sudo chown $USER.$USER /data/srv/current/auth/proxy/dbfile
    sudo chmod 0400 /data/srv/current/auth/proxy/dbfile
    echo "ls /data/srv/current/auth/proxy"
    ls -la /data/srv/current/auth/proxy/
    echo "X509_USER_PROXY=$X509_USER_PROXY"
    echo "start with /etc/secrets/dbsconfig.json"
    dbs2go -config /etc/secrets/dbsconfig.json
else
    echo "start with $PWD/dbsconfig.json"
    dbs2go -config dbsconfig.json
fi
