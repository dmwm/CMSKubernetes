#!/bin/bash

# get proxy
/data/proxy.sh $USER
sleep 2

# start exporter servers
nohup $WDIR/bin/das2go_exporter -uri http://cmsweb-k8s.web.cern.ch:8212/status 2>&1 1>& das2go_exporter.log < /dev/null &
nohup $WDIR/bin/reqmgr_exporter -namespace reqmgr -uri https://cmsweb-k8s.web.cern.ch:31443/reqmgr2/data/proc_status 2>&1 1>& reqmgr_exporter.log < /dev/null &
# start node exporter
nohup $WDIR/bin/node_exporter 2>&1 1>& node_exporter.log < /dev/null &
# start grafana server
cd $WDIR/grafana
#nohup ./bin/grafana-server web 2>&1 1>& grafana.log < /dev/null &
./bin/grafana-server web
