#! /bin/sh

export REPO=~/rucio-helm-charts
export INSTANCE=dev
export PROBE_NAME=rucio-probes-${INSTANCE}

helm install --name $PROBE_NAME --values cms-rucio-common.yaml,${INSTANCE}-db.yaml,dp-release.yaml $REPO/rucio-probes





