#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG1805a
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend frontend"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone git://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
git reset --hard $VER

# we do not use InstallDev script since it has three phases: prep, sw, post
# which setup accounts and crontab. Instead, we invoke bare Deploy script
# only to install sw part

# here is an example how to do installation through InstallDev
# sed -i -e "s,ssh,#ssh,g" $AREA/InstallDev
# $AREA/InstallDev -A $ARCH -R comp@$VER -S -s image -v $VER -r comp=$REPO -u $USER -p "$PKGS"
# lastLog=`ls -lt $WDIR/srv/.deploy/*.log | awk '{print $9}' | head -1`
# cat $lastLog

# Deploy services
cd $WDIR
curl -sO http://cmsrep.cern.ch/cmssw/repos/bootstrap.sh
sh -x ./bootstrap.sh -architecture $ARCH -path $WDIR/tmp/$VER/sw -repository $REPO -server $SERVER setup
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
