#!/bin/bash

if [ ! -d /data/certs ]; then
    mkdir /data/certs
fi
# TMP solution until k8s fix file permission for secret volume
# https://github.com/kubernetes/kubernetes/issues/34982
if [ ! -f /data/certs/robotkey.pem ] && [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /data/certs
    sudo chmod 0400 /data/certs/robotkey.pem
fi
if [ ! -f /data/certs/robotcert.pem ] && [ -f /etc/secrets/robotcert.pem ]; then
    sudo cp /etc/secrets/robotcert.pem /data/certs
fi
if [ -f /etc/secrets/robotkey.pem ] && [ -f /etc/secrets/robotcert.pem ]; then
    sudo voms-proxy-init -voms cms -rfc \
        -key /data/certs/robotkey.pem \
        -cert /data/certs/robotcert.pem \
        -out /tmp/proxy
    kubectl create secret generic proxy-secrets \
        --from-file=/data/certs/robotkey.pem \
        --from-file=/data/certs/robotcert.pem \
        --from-file=/tmp/proxy --dry-run -o yaml | \
        kubectl apply --validate=false -f -
fi
