#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG2210b
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend dbs"
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
    dbs/deploy

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

# make fake proxy to allow post install step to succeed
mkdir -p /data/srv/$VER/auth/proxy
rm /data/srv/$VER/auth/proxy/*

$WDIR/cfg/Deploy -A $ARCH -R comp@$VER -r comp=$REPO -t $VER -w $SERVER -s post $WDIR/srv "$PKGS"
if [ $? -ne 0 ]; then
    cat $WDIR/srv/.deploy/*-post.log
    exit 1
fi

# comment out usage of port 8443 in k8s setup
#files=`find /data/srv/$VER/sw/$ARCH -type f | xargs grep ":8443" | awk '{print $1}' | sed -e "s,:,,g" | grep py$`
#for fname in $files; do
#    sed -i -e "s,:8443,,g" $fname
#done

# patch DBS deployment area to separate DBS instance start-up
#cd $WDIR/srv/current/config/dbs
#curl -ksLO https://github.com/dmwm/deployment/pull/794.patch
#patch -p2 < 794.patch
### NATS patches
# get CMSMonitoring
cd /tmp
git clone https://github.com/dmwm/CMSMonitoring.git
cp -r CMSMonitoring/src/python/CMSMonitoring $WDIR/srv/current/apps/dbs/lib/python2.7/site-packages
# get tornado
cd /tmp
git clone -b v5.1.1 https://github.com/tornadoweb/tornado.git
cp -r tornado/tornado $WDIR/srv/current/apps/dbs/lib/python2.7/site-packages
curl -ksLO https://files.pythonhosted.org/packages/d9/e9/513ad8dc17210db12cb14f2d4d190d618fb87dd38814203ea71c87ba5b68/singledispatch-3.4.0.3.tar.gz
source $WDIR/srv/current/apps/dbs/etc/profile.d/init.sh
tar xfz singledispatch-3.4.0.3.tar.gz
cd singledispatch-3.4.0.3
python setup.py install --prefix=$WDIR/srv/current/apps/dbs
cd /tmp
curl -ksLO https://files.pythonhosted.org/packages/68/3c/1317a9113c377d1e33711ca8de1e80afbaf4a3c950dd0edfaf61f9bfe6d8/backports_abc-0.5.tar.gz
tar xfz backports_abc-0.5.tar.gz
cd backports_abc-0.5
python setup.py install --prefix=$WDIR/srv/current/apps/dbs
cd /tmp
curl -ksLO https://files.pythonhosted.org/packages/47/04/5fc6c74ad114032cd2c544c575bffc17582295e9cd6a851d6026ab4b2c00/futures-3.3.0.tar.gz
tar xfz futures-3.3.0.tar.gz
cd futures-3.3.0
python setup.py install --prefix=$WDIR/srv/current/apps/dbs

# get nats.io
cd /tmp
git clone https://github.com/nats-io/nats.py2.git
cp -r nats.py2/nats $WDIR/srv/current/apps/dbs/lib/python2.7/site-packages
# get dbs patches
cd $WDIR/srv/current/apps/dbs/lib/python2.7/site-packages/dbs/web
curl -ksLO https://github.com/dmwm/DBS/pull/617.patch
patch -p6 < 617.patch
cd $WDIR/srv/current/config/dbs
curl -ksLO https://github.com/dmwm/deployment/pull/821.patch
patch -p2 < 821.patch
# end of TMP block, will be removed once we get all payches in place

# replace usage of hostkey/hostcert in crontab to frontend proxy
crontab -l | \
    sed -e "s,/data/certs/hostcert.pem,/etc/secrets/proxy,g" \
        -e "s,/data/certs/hostkey.pem,/etc/secrets/proxy,g" | crontab -

# add proxy generation via robot certificate
crontab -l | egrep -v "reboot|ProxyRenew|LogArchive|ServerMonitor" > /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
