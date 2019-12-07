#!/bin/bash
set -e # exit script if error occurs

## deploy prometheus CRD
#if [ -n "`kubectl get crd | grep prometheus`" ]; then
#    kubectl delete -f bundle.yaml
#fi
#kubectl apply -f bundle.yaml
## deploy prometheus configuration
#if [ -n "`kubectl get secrets | grep prometheus-config`" ]; then
#    kubectl delete secret prometheus-config
#fi
#kubectl create secret generic prometheus-config --from-file=prometheus-config.yaml
## deploy prometheus
#if [ -n "`kubectl get pod | grep prometheus-prometheus`" ]; then
#    kubectl delete -f prometheus.yaml
#fi
#kubectl apply -f prometheus.yaml

# deploy custom prometheus
./create_secrets.sh
kubectl apply -f prometheus.yaml

# deploy pushgateway
if [ -n "`kubectl get pod | grep pushgateway`" ]; then
    kubectl delete -f pushgateway.yaml
fi
kubectl apply -f pushgateway.yaml
# deploy VictoriaMetrics
if [ -n "`kubectl get pod | grep victoria-metrics`" ]; then
    kubectl delete -f victoria-metrics.yaml
fi
# label our minions in order to use PVC
kubectl get node | grep minion | \
    awk '{print "kubectl label node "$1" failure-domain.beta.kubernetes.io/zone=nova --overwrite"}'
# add PVC storage
kubectl apply -f cinder-storage.yaml
kubectl apply -f victoria-metrics.yaml
