#!/bin/bash
# start exporter servers
nohup $WDIR/bin/das2go_exporter -uri https://cmsweb-k8s.web.cern.ch:31443/das/status 2>&1 1>& das2go_exporter.log < /dev/null &
# start node exporter
nohup $WDIR/bin/node_exporter 2>&1 1>& node_exporter.log < /dev/null &
#tail -f *exporter.log
# start grafana server
cd $WDIR/grafana
#nohup ./bin/grafana-server web 2>&1 1>& grafana.log < /dev/null &
./bin/grafana-server web
