#!/bin/bash

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    export X509_USER_PROXY=/etc/proxy/proxy
    mkdir -p /data/srv/state/$srv/proxy
    if [ -f /data/srv/state/$srv/proxy/proxy.cert ]; then
        rm /data/srv/state/$srv/proxy/proxy.cert
    fi
    ln -s /etc/proxy/proxy /data/srv/state/$srv/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    if [ -f /data/srv/current/auth/proxy/proxy ]; then
        rm /data/srv/current/auth/proxy/proxy
    fi
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# use service configuration files from /etc/secrets if they are present
cdir=/data/srv/current/config/exporters
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

# start exporter servers
nohup $WDIR/bin/das2go_exporter -address ":18217" 2>&1 1>& das2go_exporter.log < /dev/null &
nohup $WDIR/bin/reqmgr_exporter -namespace reqmgr -uri http://localhost:8246/reqmgr2/data/proc_status 2>&1 1>& reqmgr_exporter.log < /dev/null &
nohup $WDIR/bin/process_monitor.sh ".*exportersGlobalReader" exporters_global_exporter ":18250" 15 2>&1 1>& exporters_exporter.log < /dev/null &
# start node exporter
nohup $WDIR/bin/node_exporter 2>&1 1>& node_exporter.log < /dev/null &
# start grafana server
cd $WDIR/grafana
#nohup ./bin/grafana-server web 2>&1 1>& grafana.log < /dev/null &
./bin/grafana-server web
