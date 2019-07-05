#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG1907f
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend alertscollector"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone git://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
git reset --hard $VER

# Deploy services
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
$WDIR/cfg/Deploy -A $ARCH -R comp@$VER -r comp=$REPO -t $VER -w $SERVER -s post $WDIR/srv "$PKGS"
if [ $? -ne 0 ]; then
    cat $WDIR/srv/.deploy/*-post.log
    exit 1
fi

# NOTE: we separated workqueue, reqmon, alertscollector and couchdb into individual
# containers. In k8s cluster we need to remove monitoring of services which are
# not part of the container/pod. The action items below perform that.

# remove monitoring configs for services which are not run in this container
for srv in "couchdb"; do
    fname=/data/srv/current/config/$srv/monitoring.ini
    if [ -f $fname ]; then
        rm $fname
    fi
done

# Adjust ServerMonitor to be specific
sed -i -e "s#ServerMonitor/2.0#ServerMonitor-alertscollector#g" /data/srv/current/config/admin/ServerMonitor

# disable workqueue/reqmon/couch on alertscollector pod
crontab -l | egrep -v "workqueue|reqmon|couchdb|reboot" > /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
