#!/bin/bash
# create a helm_home in a working directory and export HELM_HOME:
export HELM_HOME="${PWD}/helm_home"
export HELM_TLS_ENABLE="true"
export TILLER_NAMESPACE="magnum-tiller"
ing_file=values.yaml
if [ -d $HELM_HOME ]; then
    rm -rf $HELM_HOME
fi
if [ -f $ing_file ]; then
    rm $ing_file
fi
mkdir -p $HELM_HOME
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.ca\.pem}' | base64 --decode > "${HELM_HOME}/ca.pem"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.key\.pem}' | base64 --decode > "${HELM_HOME}/key.pem"
kubectl -n magnum-tiller get secret helm-client-secret -o jsonpath='{.data.cert\.pem}' | base64 --decode > "${HELM_HOME}/cert.pem"
helm ls
helm init -c
#helm init --client-only
#helm repo update
helm get values nginx-ingress > $ing_file
helm_ver=`helm list | grep nginx-ingress | awk '{print $9}' | sed -e "s,nginx-ingress-,,g"`
echo
echo "Adjust $ing_file file to your needs, once done execute:"
echo "export HELM_HOME=\"${PWD}/helm_home\""
echo "export HELM_TLS_ENABLE=\"true\""
echo "export TILLER_NAMESPACE=\"magnum-tiller\""
echo "helm upgrade nginx-ingress stable/nginx-ingress --namespace=kube-system -f $ing_file --recreate-pods --version v$helm_ver"
