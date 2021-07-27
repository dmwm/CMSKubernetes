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

if [ ! -f /tmp/robotkey.pem ] && [ -f /etc/robots/robotkey.pem ]; then
    sudo cp /etc/robots/robotkey.pem /tmp
    sudo chmod 0400 /tmp/robotkey.pem
    sudo chown $USER /tmp/robotkey.pem
    sudo chgrp $USER /tmp/robotkey.pem
fi
if [ ! -f /tmp/robotcert.pem ] && [ -f /etc/robots/robotcert.pem ]; then
    sudo cp /etc/robots/robotcert.pem /tmp
    sudo chown $USER /tmp/robotcert.pem
    sudo chgrp $USER /tmp/robotcert.pem
fi

if [ -f /tmp/robotkey.pem ] && [ -f /tmp/robotcert.pem ]; then
    # keep proxy validity for 4 days (roll over long weekend)
    voms-proxy-init -voms cms -rfc -valid 95:50 \
        -key /tmp/robotkey.pem \
        -cert /tmp/robotcert.pem \
        -out /tmp/proxy

#### Use below section for proxy in ms-unmerged service
#    voms-proxy-init -voms cms -rfc -valid 95:50 \
#        -key /tmp/robotkey.pem \
#        -cert /tmp/robotcert.pem \
#        --voms cms:/cms/Role=production --valid 192:00 \
#        -out /tmp/proxy

        
    out=$?
    if [ $out -eq 0 ]; then
        kubectl create secret generic proxy-secrets \
            --from-file=/tmp/proxy --dry-run=client -o yaml | \
            kubectl apply --validate=false -f -

#### Use below section for proxy in ms-unmerged service
#        kubectl create secret generic proxy-secrets-ms-unmerged \
#            --from-file=/tmp/proxy --dry-run=client -o yaml | \
#            kubectl apply --validate=false -f -
            
            
            
    else
        echo "Failed to obtain new proxy, voms-proxy-init error $out"
        echo "Will not update proxy-secrets"
    fi
fi
