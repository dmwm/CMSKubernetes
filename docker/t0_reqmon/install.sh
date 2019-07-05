#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG1907f
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend t0_reqmon"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone git://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
git reset --hard $VER

# adjust deploy script
sed -i -e "s,https://cmsweb.cern.ch,https://cmsweb-test.web.cern.ch,g" \
    -e "s,https://cmsweb-testbed.cern.ch,https://cmsweb-test.web.cern.ch,g" \
    -e "s,https://cmsweb-dev.cern.ch,https://cmsweb-test.web.cern.ch,g" \
    -e "s,https://cmsweb-sec,https://cmsweb-test.web.cern.ch,g" \
    -e "s,https://\`hostname -f\`,https://cmsweb-test.web.cern.ch,g" \
    -e "s,dbs_ins=\"int\",dbs_inst=\"prod\",g" \
    -e "s,dbs_ins=\"dev\",dbs_inst=\"prod\",g" \
    -e "s,dbs_ins=\"private_vm\",dbs_inst=\"prod\",g" \
    t0_reqmon/deploy

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

# Adjust ServerMonitor to be specific
sed -i -e "s#ServerMonitor/2.0#ServerMonitor-t0_reqmon#g" /data/srv/current/config/admin/ServerMonitor

# adjust crontabs
crontab -l | egrep -v "reboot" > /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
