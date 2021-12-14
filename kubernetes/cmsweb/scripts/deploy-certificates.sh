#!/bin/bash
# helper script to deploy robot and proxy certificates secrets in all namespaces.

if [ $# -ne 1 ]; then
    echo "Usage: deploy-certificates.sh  <path_to_certificates>"
    exit 1
fi

namespaces="auth default crab das dbs dmwm http tzero wma dqm rucio ruciocm"

certificates=$1

robot_key=$certificates/robotkey.pem
robot_crt=$certificates/robotcert.pem
proxy=/tmp/$USER/proxy

voms-proxy-init -voms cms -rfc \
        --key $robot_key --cert $robot_crt --out $proxy

    for ns in $namespaces; do
        echo "---"
        echo "Create certificates secrets in namespace: $ns"

        # create secrets with our robot certificates
        kubectl create secret generic robot-secrets \
            --from-file=$robot_key --from-file=$robot_crt \
            --dry-run -o yaml | \
            kubectl apply --namespace=$ns -f -

        # create proxy secret
        if [ -f $proxy ]; then
            kubectl create secret generic proxy-secrets \
                --from-file=$proxy --dry-run -o yaml | \
                kubectl apply --namespace=$ns -f -
        fi
   done
