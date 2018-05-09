#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG1805a
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend dbs"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone git://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
git reset --hard $VER

# we do not use InstallDev script directly since we want to capture the status of
# install step script. Therefore we call Deploy script and capture its status every step
cd $WDIR
curl -sO http://cmsrep.cern.ch/cmssw/repos/bootstrap.sh
sh -x ./bootstrap.sh -architecture $ARCH -path $WDIR/tmp/$VER/sw -repository $REPO -server $SERVER setup

# deploy services
$WDIR/cfg/Deploy -A $ARCH -R comp@$VER -r comp=$REPO -t $VER -w $SERVER -s prep $WDIR/srv "$PKGS"
if [ $? -ne 0 ]; then
    cat $WDIR/srv/.deploy/*-prep.log
    exit 1
fi
$WDIR/cfg/Deploy -A $ARCH -R comp@$VER -r comp=$REPO -t $VER -w $SERVER -s sw $WDIR/srv "$PKGS"
if [ $? -ne 0 ]; then
    cat $WDIR/srv/.deploy/*-sw.log
    exit 1
fi
#$WDIR/cfg/Deploy -A $ARCH -R comp@$VER -r comp=$REPO -t $VER -w $SERVER -s post $WDIR/srv "$PKGS"
#if [ $? -ne 0 ]; then
#    cat $WDIR/srv/.deploy/*-post.log
#    exit 1
#fi
ln -s /data/srv/$VER /data/srv/current
ln -s /data/srv/current/apps.sw /data/srv/current/apps

# replace usage of hostkey/hostcert in crontab to frontend proxy
crontab -l | \
    sed -e "s,/data/certs/hostcert.pem,/etc/secrets/proxy,g" \
        -e "s,/data/certs/hostkey.pem,/etc/secrets/proxy,g" | crontab -
