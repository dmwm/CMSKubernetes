#! /bin/bash

# Defined externally
# export REPO=~/rucio-helm-charts # or rucio
# export PREFIX=dev

export INSTANCE=$PREFIX    # Ugly hack, should be the same (INSTANCE)
export SERVER_NAME=cms-rucio-$PREFIX
export DAEMON_NAME=cms-ruciod-$PREFIX
export UI_NAME=cms-webui-$PREFIX
export PROBE_NAME=cms-probe-${INSTANCE}

helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-server.yaml,${PREFIX}-rucio-server.yaml,${PREFIX}-db.yaml,${PREFIX}-release.yaml  $SERVER_NAME $REPO/rucio-server
helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${PREFIX}-rucio-daemons.yaml,${PREFIX}-db.yaml,${PREFIX}-release.yaml $DAEMON_NAME $REPO/rucio-daemons
helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-webui.yaml,${PREFIX}-rucio-webui.yaml,${PREFIX}-db.yaml $UI_NAME $REPO/rucio-ui
helm upgrade --recreate-pods --values cms-rucio-common.yaml,cms-rucio-probes.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $PROBE_NAME $REPO/rucio-probes

# statsd exporter to prometheus
helm upgrade --recreate-pods --values ${INSTANCE}-statsd-exporter.yaml statsd-exporter cms-kubernetes/rucio-statsd-exporter

# Label is key to prevent it from also syncing datasets
kubectl apply -f ${PREFIX}-sync-jobs.yaml -l syncs=rses


# List the whole system
kubectl get pods -A 

