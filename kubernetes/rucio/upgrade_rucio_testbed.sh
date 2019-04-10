#! /bin/bash

#helm upgrade --values rucio-graphite.yaml  graphite kiwigrid/graphite # Don't do PVC again
helm upgrade --values cms-rucio-common.yaml,cms-rucio-server-traefik.yaml,cms-rucio-server-testbed.yaml,cms-rucio-testbed-db.yaml cms-rucio-testbed rucio/rucio-server
helm upgrade --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-daemons-testbed.yaml,cms-rucio-testbed-db.yaml cms-ruciod-testbed rucio/rucio-daemons

# Filebeat and logstash

helm upgrade --values cms-rucio-logstash.yml,logstash-filter-testbed.yml logstash stable/logstash
helm upgrade --values cms-rucio-filebeat.yml filebeat stable/filebeat

kubectl get pods
