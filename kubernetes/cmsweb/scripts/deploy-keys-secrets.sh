#!/bin/bash
# helper script to deploy robot, proxy and token secrets in all namespaces.

if [ $# -ne 2 ]; then
    echo "Usage: deploy-key-secrets.sh <namespace>  <path_to_keys>"
    exit 1
fi

ns=$1
secret_file=$2

echo "---"
echo "Creating key secrets in namespace: $ns"
echo $secret_file
if [ -f $secret_file ]; then
    kubectl create secret generic $ns-keys-secrets \
    --from-file=$secret_file --dry-run -o yaml | \
    kubectl apply --namespace=$ns -f -
fi
