#! /bin/bash

#helm upgrade --values rucio-graphite.yaml  graphite kiwigrid/graphite # Don't do PVC again
helm upgrade --values cms-rucio-common.yaml,cms-rucio-server.yaml,cms-rucio-server-testbed.yaml,cms-rucio-testbed-db.yaml cms-rucio-testbed rucio/rucio-server
helm upgrade --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-testbed-db.yaml cms-ruciod-testbed rucio/rucio-daemons
helm upgrade --values cms-rucio-common.yaml,cms-rucio-analysis-daemons.yaml,cms-rucio-testbed-db.yaml cms-analysisd-testbed rucio/rucio-daemons

kubectl get pods
