#! /bin/bash

REPO=~/rucio-helm-charts # or rucio

SERVER_NAME=cms-rucio-dev
DAEMON_NAME=cms-ruciod-dev

helm upgrade --values cms-rucio-common.yaml,cms-rucio-server-nginx.yaml,dev-rucio-server.yaml,dev-db.yaml,dev-release.yaml  $SERVER_NAME $REPO/rucio-server
helm upgrade --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,dev-rucio-daemons.yaml,dev-db.yaml,dev-release.yaml $DAEMON_NAME $REPO/rucio-daemons

# Graphite and other services (currently not doing anything with them)
helm upgrade --values rucio-graphite.yaml,rucio-graphite-nginx.yaml,dev-graphite.yaml graphite kiwigrid/graphite

# Filebeat and logstash

helm upgrade --values cms-rucio-logstash.yml,dev-logstash-filter.yaml logstash stable/logstash
helm upgrade --values cms-rucio-filebeat.yml filebeat stable/filebeat

# Label is key to prevent it from also syncing datasets
kubectl delete configmap dataset-config
kubectl create configmap dataset-config --from-file=site-sync.yaml
kubectl apply -f dev-sync-jobs.yaml -l syncs=rses

kubectl get pods
