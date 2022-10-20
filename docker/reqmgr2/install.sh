#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG2210b
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend reqmgr2"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone https://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
git reset --hard $VER

# adjust deploy script to use k8s host name
cmsk8s_prod=${CMSK8S:-https://cmsweb.cern.ch}
cmsk8s_prep=${CMSK8S:-https://cmsweb-testbed.cern.ch}
cmsk8s_dev=${CMSK8S:-https://cmsweb-dev.cern.ch}
cmsk8s_priv=${CMSK8S:-https://cmsweb-test.web.cern.ch}
sed -i -e "s,https://cmsweb.cern.ch,$cmsk8s_prod,g" \
    -e "s,https://cmsweb-testbed.cern.ch,$cmsk8s_prep,g" \
    -e "s,https://cmsweb-dev.cern.ch,$cmsk8s_dev,g" \
    -e "s,https://\`hostname -f\`,$cmsk8s_priv,g" \
    reqmgr2/deploy

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

# TMP: add patch to WMCore to lower case Cms headers
# I still need to enable pycurl in
#cd $WDIR/srv/$VER/sw/$ARCH/cms/reqmgr2/*/lib/python2.7/site-packages/
#curl -ksLO https://github.com/dmwm/WMCore/pull/9100.patch
#patch -p3 < 9100.patch
# patch to not verify host in pycurl
#curl -ksLO https://github.com/dmwm/WMCore/pull/9101.patch
#patch -p3 < 9101.patch
#
# switch to use pycurl in Requests.py instead of default httplib2
#fname=`find /data/srv/$VER/sw/$ARCH/cms/reqmgr2/ -name Requests.py`
#sed -i -e "s#self.pycurl = idict.get('pycurl', None)#self.pycurl = True#g" $fname
#cd $WDIR
# end of TMP block, will be removed once we get it in WMCore condebase

# comment out usage of port 8443 in k8s setup
#files=`find /data/srv/$VER/sw/$ARCH -type f | xargs grep ":8443" | awk '{print $1}' | sed -e "s,:,,g" | grep py$`
#for fname in $files; do
#    sed -i -e "s,:8443,,g" $fname
#done

# NOTE: we separated workqueue, reqmon, reqmgr2 and couchdb into individual
# containers. In k8s cluster we need to remove monitoring of services which are
# not part of the container/pod. The action items below perform that.

# remove monitoring configs for services which are not run in this container
for srv in "workqueue" "reqmon" "couchdb"; do
    fname=/data/srv/current/config/$srv/monitoring.ini
    if [ -f $fname ]; then
        rm $fname
    fi
done

# Adjust ServerMonitor to be specific
sed -i -e "s#ServerMonitor/2.0#ServerMonitor-reqmgr#g" /data/srv/current/config/admin/ServerMonitor

# adjust crontabs
# disable workqueue/reqmon/couch on reqmgr pod
crontab -l | egrep -v "workqueue|reqmon|couchdb|reboot|ProxyRenew|LogArchive|ServerMonitor" > /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
