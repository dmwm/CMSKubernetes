#!/bin/bash
### This script relies on provided configuration files which will be
### be mounted to /etc/secrets area
### This area may contains the following files
### - hostkey.pem, hostcert.pem
### - hmac file used in deployment
### - proxy
### - cmsweb.services, a file contains hostname of backend k8s cluster
### - phedex.vms, couchdb.vms, empty files which will indicate that we'll use VMs
### - server.conf, frontend8443 server configuration file
### - backends.txt, frontend8443 redirect rules for backends
### - gitlab_token.txt file containing a valid gitlab token that has access to read: https://gitlab.cern.ch/cmsweb/cmsweb-blacklisting

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
if [ -f /etc/hmac/hmac ]; then
    cp /data/srv/current/auth/wmcore-auth/header-auth-key /data/srv/current/auth/wmcore-auth/header-auth-key.orig
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /data/srv/state/frontend8443/etc/keys/authz-headers /data/srv/state/frontend8443/etc/keys/authz-headers.orig
    sudo rm /data/srv/state/frontend8443/etc/keys/authz-headers
    cp /etc/hmac/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/hmac/hmac /data/srv/state/frontend8443/etc/keys/authz-headers
fi


# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    export X509_USER_PROXY=/etc/proxy/proxy
    mkdir -p /data/srv/state/frontend8443/proxy
    if [ -f /data/srv/state/frontend8443/proxy/proxy.cert ]; then
        rm /data/srv/state/frontend8443/proxy/proxy.cert
    fi
    ln -s /etc/proxy/proxy /data/srv/state/frontend8443/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    if [ -f /data/srv/current/auth/proxy/proxy ]; then
        rm /data/srv/current/auth/proxy/proxy
    fi
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# copy gitlab_token.txt from secrets
if [ -f /etc/secrets/gitlab_token.txt ]; then
    cp /etc/secrets/gitlab_token.txt /data/srv/current/auth/frontend8443/gitlab_token.txt
fi

# obtain original voms-gridmap to be used by frontend8443
if [ -f /data/srv/current/auth/proxy/proxy ] && [ -f /data/srv/current/config/frontend8443/mkvomsmap ]; then
    /data/srv/current/config/frontend8443/mkvomsmap \
        --key /data/srv/current/auth/proxy/proxy \
        --cert /data/srv/current/auth/proxy/proxy \
        -c /data/srv/current/config/frontend8443/mkgridmap.conf \
        -o /data/srv/state/frontend8443/etc/voms-gridmap.txt --vo cms --git-token-path /data/srv/current/auth/frontend8443/gitlab_token.txt
fi

# obtain original authmap to be used by frontend8443
if [ -f /etc/robots/robotkey.pem ] && [ -f /data/srv/current/config/frontend8443/mkauthmap ]; then
    /data/srv/current/config/frontend8443/mkauthmap \
        --key /etc/robots/robotkey.pem \
        --cert /etc/robots/robotcert.pem \
        -c /data/srv/current/config/frontend8443/mkauth.conf \
        -o /data/srv/state/frontend8443/etc/authmap.json --ca-cert /etc/ssl/certs/CERN-bundle.pem
fi

# check if we provided server.services explicitly and use it if necessary
if [ -f /etc/secrets/cmsweb.services ]; then
    cp /data/srv/state/frontend8443/server.conf /data/srv/state/frontend8443/server.conf.orig
    #srvs=`cat /etc/secrets/cmsweb.services | awk '{print "s,%{ENV:BACKEND}:[0-9][0-9][0-9][0-9],"$1",g"}'`
    #sed -i -e "$srvs" /data/srv/state/frontend8443/server.conf
    sed -i -e "s,%{ENV:BACKEND}:[0-9][0-9][0-9][0-9],%{ENV:BACKEND},g" /data/srv/state/frontend8443/server.conf
    srv=`cat /etc/secrets/cmsweb.services`
    sed -i "s/cmsweb-srv.cern.ch/$srv/g"  /data/srv/current/config/frontend8443/backends.txt

    # put back vms if necessary
    if [ -f /etc/secrets/vms ]; then
        #backend=`cat /etc/secrets/cmsweb.services`
        backend="%{ENV:BACKEND}"
        cat /etc/secrets/vms | awk '{print ""$1"{s,"backend","$2",g}"}' backend=$backend | awk '{print "sed -i -e \""$0"\" /data/srv/state/frontend8443/server.conf"}' | /bin/sh
        #sed -i "s,8250:,,g" /data/srv/state/frontend8443/server.conf
    fi
fi
# allow to overwrite server.conf with one supplied by configuration
if [ -f /etc/secrets/server.conf ]; then
    echo "Using /etc/secrets/server.conf"
    mv /data/srv/state/frontend8443/server.conf /data/srv/state/frontend8443/server.conf.k8s
    ln -s /etc/secrets/server.conf /data/srv/state/frontend8443/server.conf
fi

# adjust htdocs links to ensure proper redirect between k8s clusters
sed -i -e "s,\"/wmstats/\",\"/wmstats/index.html\",g" /data/srv/state/frontend8443/htdocs/index.html
sed -i -e "s,\"/workqueue/\",\"/workqueue/index.html\",g" /data/srv/state/frontend8443/htdocs/index.html
sed -i -e "s,\"/dqm/online\",\"/dqm/online/\",g" /data/srv/state/frontend8443/htdocs/index.html
sed -i -e "s,\"/dqm/offline\",\"/dqm/offline/\",g" /data/srv/state/frontend8443/htdocs/index.html
sed -i -e "s,\"/dqm/relval\",\"/dqm/relval/\",g" /data/srv/state/frontend8443/htdocs/index.html
sed -i -e "s,\"/dqm/dev\",\"/dqm/dev/\",g" /data/srv/state/frontend8443/htdocs/index.html

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/frontend8443
files=`ls $cdir`
for fname in $files; do
    if [ -f /etc/secrets/$fname ]; then
        if [ -f $cdir/$fname ]; then
            rm $cdir/$fname
        fi
        ln -s /etc/secrets/$fname $cdir/$fname
    fi
done
# link backends files
if [ -f $cdir/backends.txt ]; then
    echo "link $cdir/backends.txt"
    bfiles="backends-prod.txt backends-preprod.txt backends-dev.txt backends-k8s.txt"
    for f in $bfiles; do
        if [ -f $cdir/$f ]; then
            rm $cdir/$f
        fi
        echo "ln -s $cdir/backends.txt $cdir/$f"
        ln -s $cdir/backends.txt $cdir/$f
    done
fi

# adjust frontend8443 log file name since we need distingushed name in k8s with CephFS
hname=`hostname -s`
if [ -n $MY_POD_NAME ]; then
    hname=$MY_POD_NAME
fi
sed -i -e "s,access_log,access_log_${hname},g" \
    -e "s,error_log,error_log_${hname},g" \
    /data/srv/state/frontend8443/server.conf

# run frontend8443 server
/data/cfg/admin/InstallDev -s start
ps auxw | grep httpd

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi

# start cron daemon
sudo /usr/sbin/crond -n
