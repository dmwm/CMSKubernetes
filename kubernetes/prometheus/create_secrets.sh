#!/bin/bash
if [ ! -d secrets ]; then
    echo "No secrets area found"
    exit 1
fi
if [ -n "`kubectl get secrets | grep prometheus-secrets`" ]; then
    echo "delete  prometheus-secrets"
    kubectl delete secret prometheus-secrets
fi
ls secrets/{*.yml,*.yaml,*.json,console_libraries/*} | awk '{ORS=" "; print "--from-file="$1""}' | awk '{print "kubectl create secret generic prometheus-secrets "$0""}' | /bin/sh
