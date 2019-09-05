#! /bin/bash

REPO=~/rucio-helm-charts # or rucio

PREFIX=dev
SERVER_NAME=cms-rucio-$PREFIX
DAEMON_NAME=cms-ruciod-$PREFIX
UI_NAME=cms-webui-$PREFIX

#helm upgrade --values rucio-graphite.yaml  graphite kiwigrid/graphite # Don't do PVC again
helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-server.yaml,${PREFIX}-rucio-server.yaml,${PREFIX}-db.yaml,${PREFIX}-release.yaml  $SERVER_NAME $REPO/rucio-server
helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${PREFIX}-rucio-daemons.yaml,${PREFIX}-db.yaml,${PREFIX}-release.yaml $DAEMON_NAME $REPO/rucio-daemons
helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-webui.yaml,${PREFIX}-rucio-webui.yaml,${PREFIX}-db.yaml $UI_NAME $REPO/rucio-ui

# statsd exporter to prometheus
kubectl apply -f dev-statsd-exporter.yaml

# Filebeat and logstash

helm upgrade --values cms-rucio-logstash.yml,${PREFIX}-logstash-filter.yaml logstash stable/logstash
helm upgrade --values cms-rucio-filebeat.yml filebeat stable/filebeat

# Label is key to prevent it from also syncing datasets
# kubectl apply -f dataset-configmap.yaml
kubectl apply -f ${PREFIX}-sync-jobs.yaml -l syncs=rses

kubectl get pods

exit;

# I think this junk is just leftovers

n=0
kubectl get node -l role=ingress -o name | grep -v master | while read node; do
  # Remove any existing aliases
  openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
  echo $((n++)) > /dev/null  # must be a better way to increment...
  cnames="cms-rucio-stats-dev--load-${n}-,cms-rucio-dev--load-${n}-,cms-rucio-auth-dev--load-${n}-,cms-rucio-webui-dev--load-${n}-"
  openstack server set --os-project-name CMSRucio --property landb-alias=$cnames ${node##node/}
done

kubectl get pods
