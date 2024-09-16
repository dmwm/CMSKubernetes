#!/bin/bash
set -x
set -euo pipefail
ENV=test
kubectl create configmap logstash-crab --from-file=config/${ENV}/logstash/logstash.conf --from-file config/${ENV}/logstash/logstash.yml --dry-run=client -oyaml | kubectl apply -f -
kubectl delete pod $(kubectl get pod --no-headers -o custom-columns=":metadata.name" | grep logstash)
