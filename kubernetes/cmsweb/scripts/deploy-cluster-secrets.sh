#!/bin/bash
# helper script to deploy robot, proxy and token secrets in all namespaces.

if [ $# -ne 1 ]; then
    echo "Usage: deploy-cluster-secrets.sh  <path_to_secrets>"
    exit 1
fi

namespaces="auth default crab das dbs dmwm http tzero wma dqm rucio ruciocm"


certificates=$1

proxy=/tmp/$USER/proxy
proxy_dmwm=/tmp/$USER/proxy_dmwm
proxy_crab=/tmp/$USER/proxy_crab
proxy_msunmer=/tmp/$USER/proxy_msunmer

robot_key=$certificates/robotkey.pem
robot_crt=$certificates/robotcert.pem

touch $proxy_dmwm
touch $proxy_crab
touch $proxy_msunmer


token=/tmp/$USER/token

voms-proxy-init -voms cms -rfc \
        --key $certificates/robotkey.pem --cert $certificates/robotcert.pem --out $proxy

voms-proxy-init -voms cms -rfc \
        --key $certificates/robotkey_dmwm.pem --cert $certificates/robotcert_dmwm.pem --out $proxy_dmwm

voms-proxy-init -voms cms -rfc \
        --key $certificates/robotkey_crab.pem --cert $certificates/robotcert_crab.pem --out $proxy_crab

for ns in $namespaces; do
    echo "---"
    echo "Create certificates secrets in namespace: $ns"
    keys=$certificates/$ns-keys.txt
    echo $keys
    if [ -f $keys ]; then
        kubectl create secret generic $ns-keys-secrets \
            --from-file=$keys --dry-run=client -o yaml | \
            kubectl apply --namespace=$ns -f -
    fi

    # create secrets with our robot certificates
    case "$ns" in
        "crab")
            robot_key=$certificates/robotkey_crab.pem
            robot_crt=$certificates/robotcert_crab.pem
            proxy=$proxy_crab
            ;;
        "dmwm")
            robot_key=$certificates/robotkey_dmwm.pem
            robot_crt=$certificates/robotcert_dmwm.pem
           
            ##proxy for ms-unmerged service
            voms-proxy-init -rfc \
            -key $robot_key \
            -cert $robot_crt \
            --voms cms:/cms/Role=production --valid 192:00 \
            --out $proxy_msunmer
            
            out=$?
           
            if [ $out -eq 0 ]; then
                kubectl create secret generic proxy-secrets-ms-unmerged \
                --from-file=proxy=$proxy_msunmer --dry-run=client -o yaml | \
                kubectl apply --namespace=dmwm -f -
            fi
            ;;
        *)
            robot_key=$certificates/robotkey.pem
            robot_crt=$certificates/robotcert.pem
            proxy=$proxy
            ;;
    esac

    #create robot secrets
    kubectl create secret generic robot-secrets \
        --from-file=robotkey=$robot_key --from-file=robotcert=$robot_crt \
        --dry-run=client -o yaml | \
        kubectl apply --namespace=$ns -f -

    # create proxy secret
    if [ -f $proxy ]; then
        kubectl create secret generic proxy-secrets \
            --from-file=proxy=$proxy --dry-run=client -o yaml | \
            kubectl apply --namespace=$ns -f -
    fi

    # create client secret
    if [ -f $certificates/client_id ] && [ -f $certificates/client_secret ]; then
        kubectl create secret generic client-secrets \
            --from-file=$certificates/client_id --from-file=$certificates/client_secret --dry-run=client -o yaml | \
            kubectl apply --namespace=$ns -f -
    fi

    # create token secrets
    curl -s -d grant_type=client_credentials -d scope="profile" -u ${certificates/client_id}:${certificates/client_secret} https://cms-auth.web.cern.ch/token | jq -r '.access_token' > $token
    now=$(date +'%Y%m%d %H:%M')
    if [ -f $token ]; then
        kubectl create secret generic token-secrets \
           --from-file=$token --dry-run=client -o yaml | \
           kubectl apply --namespace=$ns -f -
        echo "$now Token created."
     else
        echo "$now Failed to create token secrets"
     fi
 done


