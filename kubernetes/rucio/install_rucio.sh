#! /bin/sh

# This script expects that you have installed your own helm3 executable. No installation of helm into kubernetes is required

export SERVER_NAME=cms-rucio-${INSTANCE}
export DAEMON_NAME=cms-ruciod-${INSTANCE}
export UI_NAME=cms-webui-${INSTANCE}
export PROBE_NAME=cms-probe-${INSTANCE}

# Rucio server, daemons, and daemons for analysis

helm3 install $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server.yaml,${INSTANCE}-rucio-server.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-server
helm3 install $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${INSTANCE}-rucio-daemons.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-daemons
helm3 install $UI_NAME --values cms-rucio-common.yaml,cms-rucio-webui.yaml,${INSTANCE}-rucio-webui.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-ui
helm3 install $PROBE_NAME --values cms-rucio-common.yaml,cms-rucio-probes.yaml,${INSTANCE}-rucio-probes.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-probes

# CMS Rucio stuff
helm3 install cms-consistency-${INSTANCE} --values cms-consistency.yaml,${INSTANCE}-consistency.yaml,${INSTANCE}-consistency-jobs.yaml ~/CMSKubernetes/helm/rucio-consistency 
helm3 install cms-cron-${INSTANCE} --values ${INSTANCE}-cronjob.yaml cms-kubernetes/rucio-cron-jobs
helm3 install loadtest-${INSTANCE} --values ${INSTANCE}-loadtest.yaml ~/CMSKubernetes/helm/rucio-loadtest
helm3 install webdav-loadtest-${INSTANCE} --values ${INSTANCE}-loadtest.yaml,webdav-loadtest.yaml ~/CMSKubernetes/helm/rucio-loadtest
helm3 install rucio-traces-${INSTANCE} --values cms-traces.yaml,${INSTANCE}-db.yaml  ~/CMSKubernetes/helm/rucio-traces

# statsd exporter to prometheus and kube-eagle monitoring
helm3 install statsd-exporter --values statsd-prometheus-mapping.yaml,${INSTANCE}-statsd-exporter.yaml cms-kubernetes/rucio-statsd-exporter
helm3 install kube-eagle --values eagle.yaml,${INSTANCE}-eagle.yaml kube-eagle/kube-eagle

# Create a job NOW to start setting the proxies.
kubectl delete job --ignore-not-found=true fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts

