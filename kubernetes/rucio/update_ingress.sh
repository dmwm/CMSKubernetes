#!/bin/bash

echo "Updating ingress for higher memory limits until CERN fixes"

export HELM_HOME=`mktemp -d`

export HELM_TLS_ENABLE="true"
export TILLER_NAMESPACE="magnum-tiller"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.ca\.pem}' | base64 --decode > "$HELM_HOME/ca.pem"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.key\.pem}' | base64 --decode > "$HELM_HOME/key.pem"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.cert\.pem}' | base64 --decode > "$HELM_HOME/cert.pem"

helm ls
helm init -c
helm get values nginx-ingress > $HELM_HOME/ing-values.yaml

echo "Replacing 64 MB with 128 MB"
grep -C 5 64Mi $HELM_HOME/ing-values.yaml 
sed -e "s/64Mi/128Mi/g" $HELM_HOME/ing-values.yaml > $HELM_HOME/ing-values-new.yaml

echo "Upgrading modified chart and restarting pods"
helm upgrade nginx-ingress stable/nginx-ingress  --namespace=kube-system -f $HELM_HOME/ing-values-new.yaml --recreate-pods

