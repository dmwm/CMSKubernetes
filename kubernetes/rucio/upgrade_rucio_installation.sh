#! /bin/bash

helm upgrade --values rucio-graphite.yaml --values rucio-graphite-ingress.yaml  --values rucio-graphite-pvc.yaml  graphite stable/graphite 
helm upgrade --values cms-rucio-common.yaml --values cms-rucio-server.yaml cms-rucio-testbed rucio/rucio-server
helm upgrade --values cms-rucio-common.yaml --values cms-rucio-daemons.yaml cms-ruciod-testbed rucio/rucio-daemons

kubectl get pods
