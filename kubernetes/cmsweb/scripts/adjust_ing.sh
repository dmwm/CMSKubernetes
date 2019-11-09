#!/bin/bash
# create a helm_home in a working directory and export HELM_HOME:
mkdir -p $HOME/ws/helm_home
export HELM_HOME="$HOME/ws/helm_home"
rm -rf $HELM_HOME
mkdir -p $HELM_HOME
export HELM_TLS_ENABLE="true"
export TILLER_NAMESPACE="magnum-tiller"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.ca\.pem}' | base64 --decode > "$HELM_HOME/ca.pem"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.key\.pem}' | base64 --decode > "$HELM_HOME/key.pem"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.cert\.pem}' | base64 --decode > "$HELM_HOME/cert.pem"

helm ls
helm init -c
helm get values nginx-ingress > ing-values.yaml
echo
echo "Now you can edit ing-values.yaml"
echo "and then you can upload new ing values into your cluster using the following command"
echo
echo "helm upgrade nginx-ingress stable/nginx-ingress  --namespace=kube-system -f ing-values.yaml --recreate-pods"
