#! /bin/bash

# Defined externally
# export REPO=~/rucio-helm-charts # or rucio
# export INSTANCE=dev

export SERVER_NAME=cms-rucio-${INSTANCE}
export DAEMON_NAME=cms-ruciod-${INSTANCE}
export UI_NAME=cms-webui-${INSTANCE}
export PROBE_NAME=cms-probe-${INSTANCE}

helm3 upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-server.yaml,${INSTANCE}-rucio-server.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml  $SERVER_NAME $REPO/rucio-server
helm3 upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${INSTANCE}-rucio-daemons.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $DAEMON_NAME $REPO/rucio-daemons
helm3 upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-webui.yaml,${INSTANCE}-rucio-webui.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $UI_NAME $REPO/rucio-ui
helm3 upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-probes.yaml,${INSTANCE}-rucio-probes.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $PROBE_NAME $REPO/rucio-probes

# statsd exporter to prometheus
helm3 upgrade --recreate-pods --values statsd-prometheus-mapping.yaml,${INSTANCE}-statsd-exporter.yaml statsd-exporter cms-kubernetes/rucio-statsd-exporter
helm3 upgrade --recreate-pods --values eagle.yaml,${INSTANCE}-eagle.yaml kube-eagle kube-eagle/kube-eagle

# Label is key to prevent it from also syncing datasets
kubectl apply -f ${INSTANCE}-sync-jobs.yaml -l syncs=rses

# List the whole system
kubectl get pods -A 
