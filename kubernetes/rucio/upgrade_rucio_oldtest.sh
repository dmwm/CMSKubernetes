#! /bin/bash

helm upgrade --values rucio-graphite.yaml  graphite stable/graphite # Don't do PVC again
helm upgrade --values cms-rucio-common.yaml,cms-rucio-server.yaml,cms-rucio-server-oldtest.yaml,cms-rucio-oldtest-db.yaml cms-rucio-testbed rucio/rucio-server
helm upgrade --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-oldtest-db.yaml cms-ruciod-testbed rucio/rucio-daemons
helm upgrade --values cms-rucio-common.yaml,cms-rucio-analysis-daemons.yaml,cms-rucio-oldtest-db.yaml cms-analysisd-testbed rucio/rucio-daemons

kubectl get pods
