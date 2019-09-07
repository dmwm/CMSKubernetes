#!/bin/bash
# obtain CERN CAs if they're not present
#n=`ls /etc/pki/tls/private/*.key 2> /dev/null | wc -c`
#if [ "$n" -eq "0" ]; then
#    sudo /usr/sbin/cern-get-certificate --autoenroll
#    ckey=`ls /etc/pki/tls/private/*.key | tail -1`
#    host=`basename $ckey | sed -e "s,.key,,g"`
#    cert=`ls /etc/pki/tls/certs/$host.pem`
#    sudo cp $ckey /data/certs/hostkey.pem
#    sudo cp $cert /data/certs/hostcert.pem
#fi
if [ -f /etc/secrets/hostkey.pem ]; then
    # overwrite host PEM files in /data/certs since we used them during installation time
    echo "Use /etc/secrets/host{key,cert}.pem for /data/certs"
    sudo cp /etc/secrets/hostkey.pem /data/certs/
    sudo cp /etc/secrets/hostcert.pem /data/certs/
elif [ -f /etc/grid-security/hostkey.pem ]; then
    # overwrite host PEM files in /data/certs since we used them during installation time
    echo "Use /etc/grid-security/host{key,cert}.pem for /data/certs"
    sudo cp /etc/grid-security/hostkey.pem /data/certs/
    sudo cp /etc/grid-security/hostcert.pem /data/certs/
fi
# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    cp /data/srv/current/auth/wmcore-auth/header-auth-key /data/srv/current/auth/wmcore-auth/header-auth-key.orig
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /data/srv/state/frontend/etc/keys/authz-headers /data/srv/state/frontend/etc/keys/authz-headers.orig
    sudo rm /data/srv/state/frontend/etc/keys/authz-headers
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/state/frontend/etc/keys/authz-headers
fi

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    export X509_USER_PROXY=/etc/proxy/proxy
    mkdir -p /data/srv/state/frontend/proxy
    if [ -f /data/srv/state/frontend/proxy/proxy.cert ]; then
        rm /data/srv/state/frontend/proxy/proxy.cert
    fi
    ln -s /etc/proxy/proxy /data/srv/state/frontend/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    if [ -f /data/srv/current/auth/proxy/proxy ]; then
        rm /data/srv/current/auth/proxy/proxy
    fi
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# obtain original voms-gridmap to be used by frontend
if [ -f /data/srv/current/auth/proxy/proxy ] && [ -f /data/srv/current/config/frontend/mkvomsmap ]; then
    /data/srv/current/config/frontend/mkvomsmap \
        --key /data/srv/current/auth/proxy/proxy \
        --cert /data/srv/current/auth/proxy/proxy \
        -c /data/srv/current/config/frontend/mkgridmap.conf \
        -o /data/srv/state/frontend/etc/voms-gridmap.txt --vo cms
fi

# check if we provided server.conf explicitly and use it if necessary
if [ -f /etc/secrets/server.conf ]; then
    sudo rm /data/srv/state/frontend/server.conf
    ln -s /etc/secrets/server.conf /data/srv/state/frontend/server.conf
fi

# check if we provided server.services explicitly and use it if necessary
if [ -f /etc/secrets/cmsweb.services ]; then
    srvs=`cat /etc/secrets/cmsweb.services | awk '{print "s,%{ENV:BACKEND}:[0-9][0-9][0-9][0-9],"$1",g"}'`
    sed -i -e "$srvs" /data/srv/state/frontend/server.conf
fi

# adjust htdocs links to ensure proper redirect between k8s clusters
sed -i -e "s,\"/wmstats/\",\"/wmstats/index.html\",g" /data/srv/state/frontend/htdocs/index.html
sed -i -e "s,\"/workqueue/\",\"/workqueue/index.html\",g" /data/srv/state/frontend/htdocs/index.html
sed -i -e "s,\"/dqm/online\",\"/dqm/online/\",g" /data/srv/state/frontend/htdocs/index.html
sed -i -e "s,\"/dqm/offline\",\"/dqm/offline/\",g" /data/srv/state/frontend/htdocs/index.html
sed -i -e "s,\"/dqm/relval\",\"/dqm/relval/\",g" /data/srv/state/frontend/htdocs/index.html
sed -i -e "s,\"/dqm/dev\",\"/dqm/dev/\",g" /data/srv/state/frontend/htdocs/index.html

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/frontend
files=`ls $cdir`
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $cdir/$fname ]; then
            rm $cdir/$fname
        fi
        sudo cp /etc/secrets/$fname $cdir/$fname
        sudo chown $USER.$USER $cdir/$fname
    fi
done

# run frontend server
/data/cfg/admin/InstallDev -s start
ps auxw | grep httpd

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# start cron daemon
sudo /usr/sbin/crond -n
