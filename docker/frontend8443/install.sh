#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG2211a
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend frontend8443"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone https://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
#git reset --hard $VER

# adjust deploy script to use k8s host name
cmsk8s_srv=${CMSK8S_SRV:-https://cmsweb-srv.cern.ch}
cmsk8s_prod=${CMSK8S:-https://cmsweb.cern.ch}
cmsk8s_prep=${CMSK8S:-https://cmsweb-testbed.cern.ch}
cmsk8s_dev=${CMSK8S:-https://cmsweb-dev.cern.ch}
cmsk8s_priv=${CMSK8S:-https://cmsweb-test.cern.ch}
cmsweb_env=${CMSWEB_ENV:-preprod}
echo "cmsweb_env=$cmsweb_env"
echo "cmsk8s_prod=$cmsk8s_prod"
sed -i -e "s,https://cmsweb.cern.ch,$cmsk8s_prod,g" \
    -e "s,https://cmsweb-testbed.cern.ch,$cmsk8s_prep,g" \
    -e "s,https://cmsweb-dev.cern.ch,$cmsk8s_dev,g" \
    -e "s,https://\`hostname -f\`,$cmsk8s_priv,g" \
    frontend8443/deploy

if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod" ]] ; then
	cp $WDIR/cfg/frontend8443/backends-k8s-prod.txt $WDIR/cfg/frontend8443/backends.txt
else
        cp $WDIR/cfg/frontend8443/backends-k8s-preprod.txt $WDIR/cfg/frontend8443/backends.txt
fi


# overwrite dev/preprod backends with production one for k8s
files="backends-prod.txt backends-preprod.txt backends-dev.txt backends-k8s.txt backends-k8s-prod.txt backends-k8s-preprod.txt"
for fname in $files; do
    rm $WDIR/cfg/frontend8443/$fname
    ln -s $WDIR/cfg/frontend8443/backends.txt $WDIR/cfg/frontend8443/$fname
done

# we do not use InstallDev script directly since we want to capture the status of
# install step script. Therefore we call Deploy script and capture its status every step
cd $WDIR
curl -sO http://cmsrep.cern.ch/cmssw/repos/bootstrap.sh
sh -x ./bootstrap.sh -architecture $ARCH -path $WDIR/tmp/$VER/sw -repository $REPO -server $SERVER setup

cat $WDIR/cfg/frontend8443/deploy | egrep -v "80|443" > $WDIR/cfg/frontend8443/deploy.new
mv $WDIR/cfg/frontend8443/deploy $WDIR/cfg/frontend8443/deploy.orig
mv $WDIR/cfg/frontend8443/deploy.new $WDIR/cfg/frontend8443/deploy
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

# replace usage of hostkey/hostcert in crontab to frontend proxy
crontab -l | \
    sed -e "s,/data/certs/hostcert.pem,/data/srv/current/auth/proxy/proxy,g" \
        -e "s,/data/certs/hostkey.pem,/data/srv/current/auth/proxy/proxy,g" | crontab -

# add proxy generation via robot certificate
crontab -l | egrep -v "reboot|ProxyRenew|LogArchive|ServerMonitor" > /tmp/mycron
echo "0 0 * * * sudo /usr/sbin/fetch-crl" >> /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
