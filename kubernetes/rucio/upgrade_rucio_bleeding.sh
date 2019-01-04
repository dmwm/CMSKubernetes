#! /bin/bash

# Upgrade the old testbed but from git versions of the helm charts not yet accessible in a repo

#helm upgrade --values rucio-graphite.yaml  graphite kiwigrid/graphite # Don't do PVC again
helm upgrade --values cms-rucio-common.yaml,cms-rucio-server.yaml,cms-rucio-server-oldtest.yaml,cms-rucio-oldtest-db.yaml cms-rucio-testbed rucio/rucio-server
helm upgrade --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-oldtest-db.yaml cms-ruciod-testbed ~/rucio-helm-charts/rucio-daemons
helm upgrade --values cms-rucio-common.yaml,cms-rucio-analysis-daemons.yaml,cms-rucio-oldtest-db.yaml cms-analysisd-testbed  ~/rucio-helm-charts/rucio-daemons

kubectl get pods
