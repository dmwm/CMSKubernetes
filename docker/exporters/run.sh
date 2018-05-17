#!/bin/bash
# get proxy
echo "USER=$USER"
sudo /data/proxy.sh $USER
ls -la /data/srv/current/auth/proxy/proxy
# start exporter servers
nohup $WDIR/bin/das2go_exporter -uri http://cmsweb-k8s.web.cern.ch:8212/status 2>&1 1>& das2go_exporter.log < /dev/null &
# start node exporter
nohup $WDIR/bin/node_exporter 2>&1 1>& node_exporter.log < /dev/null &
# start grafana server
cd $WDIR/grafana
#nohup ./bin/grafana-server web 2>&1 1>& grafana.log < /dev/null &
./bin/grafana-server web
