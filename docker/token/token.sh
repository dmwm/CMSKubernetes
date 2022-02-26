#!/bin/bash

if [ -f /etc/client/client_id ] && [ -f /etc/client/client_secret ]; then
    export client_id=`cat /etc/client/client_id`
    export client_secret=`cat /etc/client/client_secret`
    curl -s -d grant_type=client_credentials -d scope="profile" -u ${client_id}:${client_secret} https://cms-auth.web.cern.ch/token | jq -r '.access_token' > /tmp/token

    now=$(date +'%Y%m%d %H:%M')
    if [ -f /tmp/token ]; then
        kubectl create secret generic token-secrets \
            --from-file=/tmp/token --dry-run=client -o yaml | \
            kubectl apply --validate=false -f -
        echo "$now Token created."
    else
        echo "$now Failed to create token secrets"
    fi
    ls -l /tmp/token
fi
