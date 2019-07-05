#!/bin/bash

# TMP solution until k8s fix file permission for secret volume
# https://github.com/kubernetes/kubernetes/issues/34982
if [ ! -f /tmp/robotkey.pem ] && [ -f /etc/secrets/robotkey.pem ]; then
    sudo cp /etc/secrets/robotkey.pem /tmp
    sudo chmod 0400 /tmp/robotkey.pem
    sudo chown $USER /tmp/robotkey.pem
    sudo chgrp $USER /tmp/robotkey.pem
fi
if [ ! -f /tmp/robotcert.pem ] && [ -f /etc/secrets/robotcert.pem ]; then
    sudo cp /etc/secrets/robotcert.pem /tmp
    sudo chown $USER /tmp/robotcert.pem
    sudo chgrp $USER /tmp/robotcert.pem
fi
if [ -f /tmp/robotkey.pem ] && [ -f /tmp/robotcert.pem ]; then
    voms-proxy-init -voms cms -rfc \
        -key /tmp/robotkey.pem \
        -cert /tmp/robotcert.pem \
        -out /tmp/proxy
    kubectl create secret generic proxy-secrets \
        --from-file=/tmp/proxy --dry-run -o yaml | \
        kubectl apply --validate=false -f -
fi
