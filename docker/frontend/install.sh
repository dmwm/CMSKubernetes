#!/bin/bash

ARCH=slc7_amd64_gcc630
VER=HG2401a
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend frontend"
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
    frontend/deploy

# replace backend nodes
#k8host=`echo $cmsk8s_prod | sed -e "s,\.cern\.ch,,g" -e "s,http://,,g" -e "s,https://,,g"`
#k8host=`echo $cmsk8s_srv | sed -e "s,\.cern\.ch,,g" -e "s,http://,,g" -e "s,https://,,g"`
#sed -i -e "s,vocms[0-9]*,$k8host,g" $WDIR/cfg/frontend/backends-prod.txt
#sed -i -e "s,|$k8host,,g" $WDIR/cfg/frontend/backends-prod.txt
# let's correct substitutions
#sed -i -e "s,cern.ch.cern.ch,cern.ch,g" $WDIR/cfg/frontend/backends-prod.txt
# cat whole file except last line
#cat $WDIR/cfg/frontend/backends-prod.txt | sed \$d > b.txt
# add httpgo redirect rule to k8s backend cluster
#echo "^/auth/complete/httpgo(?:/|$)" $cmsk8s_prod >> b.txt
# all other will go to our k8host
#echo "^ ${k8host}.cern.ch" >> b.txt
#rm $WDIR/cfg/frontend/backends-prod.txt
if [[ "$CMSWEB_ENV" == "production"  ||  "$CMSWEB_ENV" == "prod" ]] ; then
	cp $WDIR/cfg/frontend/backends-k8s-prod.txt $WDIR/cfg/frontend/backends.txt
else
        cp $WDIR/cfg/frontend/backends-k8s-preprod.txt $WDIR/cfg/frontend/backends.txt
fi
# add rules for httpgo
# add nossl rule for httpgo
cat > $WDIR/cfg/frontend/app_httpgo_nossl.conf << EOF_nossl
RewriteRule ^(/httpgo(/.*)?)$ https://%{SERVER_NAME}\${escape:\$1}%{env:CMS_QUERY} [R=301,NE,L]
EOF_nossl
# add ssl rule for httpgo
cat > $WDIR/cfg/frontend/app_httpgo_ssl.conf << EOF_ssl
RewriteRule ^(/httpgo(/.*)?)$ /auth/verify\${escape:\$1} [QSA,PT,E=AUTH_SPEC:cert]
RewriteRule ^/auth/complete(/httpgo(/.*)?)$ http://%{ENV:BACKEND}:8888\${escape:\$1} [QSA,P,L,NE]
EOF_ssl
# add imagebot rule
cat > $WDIR/cfg/frontend/app_imagebot_ssl.conf << EOF_ibot
RewriteRule ^(/imagebot(/.*)?)$ http://imagebot.http.svc.cluster.local:8111\${escape:\$1} [QSA,P,L,NE]
EOF_ibot


# overwrite dev/preprod backends with production one for k8s
files="backends-k8s-prod.txt backends-k8s-preprod.txt"
for fname in $files; do
    rm $WDIR/cfg/frontend/$fname
    ln -s $WDIR/cfg/frontend/backends.txt $WDIR/cfg/frontend/$fname
done

# we do not use InstallDev script directly since we want to capture the status of
# install step script. Therefore we call Deploy script and capture its status every step
cd $WDIR
curl -sO http://cmsrep.cern.ch/cmssw/repos/bootstrap.sh
sh -x ./bootstrap.sh -architecture $ARCH -path $WDIR/tmp/$VER/sw -repository $REPO -server $SERVER setup

# TMP: add traefik headers support for our frontend
#cd $WDIR/cfg
#curl -ksLO https://github.com/dmwm/deployment/pull/716.patch
#patch -p1 < 716.patch
#sed -i -e "s,X-Forwarded-Ssl-Client-Cert,X-Forwarded-Tls-Client-Cert,g" frontend/cmsauth.pm
#sed -i -e "s,X-Forwarded-Ssl-Client-Cert,X-Forwarded-Tls-Client-Cert,g" frontend/cmsnuke.pm
#cd $WDIR
# end of TMP block, will be removed once we get it in frontend codebase

# TMP: https://stackoverflow.com/questions/18742156/certificate-verification-error-20-unable-to-get-local-issuer-certificate-c
# disable SSLVerifyClient optional to test ingress-nginx
#cd $WDIR/cfg
#sed -i -e "s,SSLVerifyClient optional,#SSLVerifyClient optional,g" frontend/frontend.conf
#cd $WDIR
# end of TMP block

# deploy services
cat $WDIR/cfg/frontend/deploy | egrep -v "80|443" > $WDIR/cfg/frontend/deploy.new
mv $WDIR/cfg/frontend/deploy $WDIR/cfg/frontend/deploy.orig
mv $WDIR/cfg/frontend/deploy.new $WDIR/cfg/frontend/deploy
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
sed -i '/mkauthmap/d' /tmp/mycron
./copy_cron.sh && cat /tmp/authmap.cron >> /tmp/mycron

crontab /tmp/mycron
rm /tmp/mycron
