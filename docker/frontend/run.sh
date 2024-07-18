#!/bin/bash
### This script relies on provided configuration files which will be
### be mounted to /etc/secrets area
### This area may contains the following files
### - hostkey.pem, hostcert.pem
### - hmac file used in deployment
### - proxy
### - cmsweb.services, a file contains hostname of backend k8s cluster
### - phedex.vms, couchdb.vms, empty files which will indicate that we'll use VMs
### - server.conf, frontend server configuration file
### - backends.txt, frontend redirect rules for backends
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
    cp /data/srv/state/frontend/etc/keys/authz-headers /data/srv/state/frontend/etc/keys/authz-headers.orig
    sudo rm /data/srv/state/frontend/etc/keys/authz-headers
    cp /etc/hmac/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/hmac/hmac /data/srv/state/frontend/etc/keys/authz-headers
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

# copy gitlab_token.txt from secrets
if [ -f /etc/secrets/gitlab_token.txt ]; then
    cp /etc/secrets/gitlab_token.txt /data/srv/current/auth/frontend/gitlab_token.txt
fi

# obtain original voms-gridmap to be used by frontend
if [ -f /data/srv/current/auth/proxy/proxy ] && [ -f /data/srv/current/config/frontend/mkvomsmap ]; then
    /data/srv/current/config/frontend/mkvomsmap \
        --key /data/srv/current/auth/proxy/proxy \
        --cert /data/srv/current/auth/proxy/proxy \
        -c /data/srv/current/config/frontend/mkgridmap.conf \
        -o /data/srv/state/frontend/etc/voms-gridmap.txt --vo cms --git-token-path /data/srv/current/auth/frontend/gitlab_token.txt
fi

# obtain original authmap to be used by frontend
if [ -f /etc/robots/robotkey.pem ] && [ -f /data/srv/current/config/frontend/mkauthmap ]; then
    /data/srv/current/config/frontend/mkauthmap \
        --key /etc/robots/robotkey.pem \
        --cert /etc/robots/robotcert.pem \
        -c /data/srv/current/config/frontend/mkauth.conf \
        -o /data/srv/state/frontend/etc/authmap.json --ca-cert /etc/ssl/certs/CERN-bundle.pem
fi

# check if we provided server.services explicitly and use it if necessary
if [ -f /etc/secrets/cmsweb.services ]; then
    cp /data/srv/state/frontend/server.conf /data/srv/state/frontend/server.conf.orig
    #srvs=`cat /etc/secrets/cmsweb.services | awk '{print "s,%{ENV:BACKEND}:[0-9][0-9][0-9][0-9],"$1",g"}'`
    #sed -i -e "$srvs" /data/srv/state/frontend/server.conf
    sed -i -e "s,%{ENV:BACKEND}:[0-9][0-9][0-9][0-9],%{ENV:BACKEND},g" /data/srv/state/frontend/server.conf
    srv=`cat /etc/secrets/cmsweb.services`
    sed -i "s/cmsweb-srv.cern.ch/$srv/g"  /data/srv/current/config/frontend/backends.txt

    # put back vms if necessary
    if [ -f /etc/secrets/vms ]; then
        #backend=`cat /etc/secrets/cmsweb.services`
        backend="%{ENV:BACKEND}"
        cat /etc/secrets/vms | awk '{print ""$1"{s,"backend","$2",g}"}' backend=$backend | awk '{print "sed -i -e \""$0"\" /data/srv/state/frontend/server.conf"}' | /bin/sh
        #sed -i "s,8250:,,g" /data/srv/state/frontend/server.conf
    fi
fi
# allow to overwrite server.conf with one supplied by configuration
if [ -f /etc/secrets/server.conf ]; then
    echo "Using /etc/secrets/server.conf"
    mv /data/srv/state/frontend/server.conf /data/srv/state/frontend/server.conf.k8s
    ln -s /etc/secrets/server.conf /data/srv/state/frontend/server.conf
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

# adjust frontend log file name since we need distingushed name in k8s with CephFS
hname=`hostname -s`
if [ -n $MY_POD_NAME ]; then
    hname=$MY_POD_NAME
fi
sed -i -e "s,access_log,access_log_${hname},g" \
    -e "s,error_log,error_log_${hname},g" \
    /data/srv/state/frontend/server.conf

### Following commands will generate authentication maps.

/data/srv/current/config/frontend/mkvomsmap  -c /data/srv/current/config/frontend/mkauth.conf -o /data/srv/state/frontend/etc/voms-gridmap.txt --cert /etc/robots/robotcert.pem --key /etc/robots/robotkey.pem --ca-cert /etc/ssl/certs/CERN-bundle.pem ; [ $? -ne 0 ] && /bin/bash /data/alerts.sh

/data/srv/current/config/frontend/mkauthmap  -c /data/srv/current/config/frontend/mkauth.conf -o /data/srv/state/frontend/etc/authmap.json --cert /etc/robots/robotcert.pem --key /etc/robots/robotkey.pem --ca-cert /etc/ssl/certs/CERN-bundle.pem ; [ $? -ne 0 ] && /bin/bash /data/alerts.sh

ls -l /data/srv/state/frontend/etc/authmap.json

if [ -f /data/srv/state/frontend/etc/authmap.json ]; then
  if [ -f /etc/secrets/keytab ]; then
    export keytab=/etc/secrets/keytab
    principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
    kinit $principal -k -t "$keytab" 2>&1 1>& /dev/null
    if [ $? == 1 ]; then
      echo "Unable to perform kinit operation for cmsweb keytab."
      exit 1
    fi
    cp /eos/user/c/cmsweb/authmap.json /data/srv/state/frontend/etc/authmap.json
  fi
fi

# run frontend server
/data/cfg/admin/InstallDev -s start
ps auxw | grep httpd

# run monitoring script
if [ -f /data/monitor.sh ]; then
    /data/monitor.sh
fi
crontab -l
#fixing the crontab depending on the environment to avoid putting heavy load on CRIC servers.
./copy_cron.sh && (crontab -l ; cat /tmp/authmap.cron) | crontab -
# start cron daemon
sudo /usr/sbin/crond -n
