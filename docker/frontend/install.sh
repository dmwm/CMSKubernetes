#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG1903g
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend frontend"
SERVER=cmsrep.cern.ch

cd $WDIR
git clone git://github.com/dmwm/deployment.git cfg
mkdir $WDIR/srv

cd $WDIR/cfg
git reset --hard $VER

# replace backend nodes
files=`ls $WDIR/cfg/frontend/backend*.txt`
for f in $files; do
    sed -i -e "s,vocms[0-9]*,cmsweb-test.web,g" $f
    sed -i -e "s,|cmsweb-test.web.cern.ch,,g" $f
done

# overwrite dev/preprod backends with production one for k8s
/bin/cp -r $WDIR/cfg/frontend/backends-prod.txt $WDIR/cfg/frontend/backends-dev.txt
/bin/cp -r $WDIR/cfg/frontend/backends-prod.txt $WDIR/cfg/frontend/backends-preprod.txt

# we do not use InstallDev script directly since we want to capture the status of
# install step script. Therefore we call Deploy script and capture its status every step
cd $WDIR
curl -sO http://cmsrep.cern.ch/cmssw/repos/bootstrap.sh
sh -x ./bootstrap.sh -architecture $ARCH -path $WDIR/tmp/$VER/sw -repository $REPO -server $SERVER setup

# TMP: add traefik headers support for our frontend
cd $WDIR/cfg
curl -ksLO https://github.com/dmwm/deployment/pull/716.patch
patch -p1 < 716.patch
sed -i -e "s,X-Forwarded-Ssl-Client-Cert,X-Forwarded-Tls-Client-Cert,g" frontend/cmsauth.pm
sed -i -e "s,X-Forwarded-Ssl-Client-Cert,X-Forwarded-Tls-Client-Cert,g" frontend/cmsnuke.pm
cd $WDIR
# end of TMP block, will be removed once we get it in frontend codebase

# TMP: https://stackoverflow.com/questions/18742156/certificate-verification-error-20-unable-to-get-local-issuer-certificate-c
# disable SSLVerifyClient optional to test ingress-nginx
#cd $WDIR/cfg
#sed -i -e "s,SSLVerifyClient optional,#SSLVerifyClient optional,g" frontend/frontend.conf
#cd $WDIR
# end of TMP block

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

# replace usage of hostkey/hostcert in crontab to frontend proxy
crontab -l | \
    sed -e "s,/data/certs/hostcert.pem,/data/srv/current/auth/proxy/proxy,g" \
        -e "s,/data/certs/hostkey.pem,/data/srv/current/auth/proxy/proxy,g" | crontab -

# add proxy generation via robot certificate
crontab -l > /tmp/mycron
echo "3 */3 * * * sudo /data/proxy.sh $USER 2>&1 1>& /dev/null" >> /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
