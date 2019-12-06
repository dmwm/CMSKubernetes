#!/bin/bash
# deploy prometheus CRD
if [ -z `kubectl get crd | grep prometheus` ]; then
    kubectl delete -f bundle.yaml
fi
kubectl apply -f bundle.yaml
# deploy prometheus configuration
if [ -z `kubectl get secrets | grep prometheus-config` ]; then
    kubectl delete secret prometheus-config
fi
kubectl create secret generic prometheus-config --from-file=prometheus-config.yaml
# deploy prometheus
if [ -z `kubectl get pod | grep prometheus-prometheus` ]; then
    kubectl delete -f prometheus.yaml
fi
kubectl apply -f prometheus.yaml
# deploy pushgateway
if [ -z `kubectl get pod | grep pushgateway` ]; then
    kubectl delete -f pushgateway.yaml
fi
kubectl apply -f pushgateway.yaml
# deploy VictoriaMetrics
if [ -z `kubectl get pod | grep victoria-metrics` ]; then
    kubectl delete -f victoria-metrics.yaml
fi
kubectl apply -f victoria-metrics.yaml
