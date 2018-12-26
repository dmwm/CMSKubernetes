#! /bin/sh

# Rucio server, daemons, and daemons for analysis

helm install --name cms-rucio-testbed --values cms-rucio-common.yaml,cms-rucio-server.yaml,cms-rucio-server-oldtest.yaml,cms-rucio-oldtest-db.yaml rucio/rucio-server
helm install --name cms-ruciod-testbed --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-oldtest-db.yaml rucio/rucio-daemons
helm install --name cms-analysisd-testbed --values cms-rucio-common.yaml,cms-rucio-analysis-daemons.yaml,cms-rucio-oldtest-db.yaml rucio/rucio-daemons

# Graphite and other services
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-ingress.yaml,rucio-graphite-pvc.yaml kiwigrid/graphite
