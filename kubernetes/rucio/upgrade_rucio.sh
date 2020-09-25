#! /bin/bash

# Defined externally
# export REPO=~/rucio-helm-charts # or rucio
# export INSTANCE=dev

export SERVER_NAME=cms-rucio-${INSTANCE}
export DAEMON_NAME=cms-ruciod-${INSTANCE}
export UI_NAME=cms-webui-${INSTANCE}
export PROBE_NAME=cms-probe-${INSTANCE}

helm3 upgrade --values cms-rucio-common.yaml,cms-rucio-server.yaml,${INSTANCE}-rucio-server.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml  $SERVER_NAME $REPO/rucio-server
helm3 upgrade --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${INSTANCE}-rucio-daemons.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $DAEMON_NAME $REPO/rucio-daemons
helm3 upgrade --values cms-rucio-common.yaml,cms-rucio-webui.yaml,${INSTANCE}-rucio-webui.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $UI_NAME $REPO/rucio-ui
helm3 upgrade --values cms-rucio-common.yaml,cms-rucio-probes.yaml,${INSTANCE}-rucio-probes.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $PROBE_NAME $REPO/rucio-probes

# CMS Stuff
# helm3 upgrade --values cms-consistency.yaml,${INSTANCE}-consistency.yaml,${INSTANCE}-consistency-jobs.yaml cms-consistency-${INSTANCE} ~/CMSKubernetes/helm/rucio-consistency
helm3 upgrade --values ${INSTANCE}-cronjob.yaml cms-cron-${INSTANCE} cms-kubernetes/rucio-cron-jobs


# statsd exporter to prometheus, and Eagle reporting MONIT
helm3 upgrade --values statsd-prometheus-mapping.yaml,${INSTANCE}-statsd-exporter.yaml statsd-exporter cms-kubernetes/rucio-statsd-exporter
helm3 upgrade --values eagle.yaml,${INSTANCE}-eagle.yaml kube-eagle kube-eagle/kube-eagle

# List the whole system
kubectl get pods -A 
