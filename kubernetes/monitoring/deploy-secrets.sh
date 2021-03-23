#!/bin/bash
##H Usage: deploy-secrets.sh NAMESPACE SECRET-NAME <HA>
##H
##H Examples:
##H        deploy-secrets.sh default alertmanager-secrets
##H        deploy-secrets.sh default prometheus-secrets ha
##H        deploy-secrets.sh default karma-secrets ha1
set -e # exit script if error occurs

# help definition
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

# define configuration and secrets areas
configDir=cmsmon-configs
secretDir=secrets

# --- DO NOT CHANGE BELOW THIS LINE --- #
ns=$1
secret=$2
ha=""
if [ $@ -eq 3 ]; then
    ha=$3
fi

kubectl -n $ns delete secret $secret
if [ "$secret" == "prometheus-secrets" ]; then
    prom="$configDir/prometheus/prometheus.yaml"
    if [ $ha -ne "" ]; then
        prom="$configDir/prometheus/ha/prometheus.yaml"
    fi
    files=`ls $configDir/prometheus/*.rules $configDir/prometheus/*.json $prom | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "alertmanager-secrets" ]; then
    username=`cat $secretDir/alertmanager/secrets | grep USERNAME`
    password=`cat $secretDir/alertmanager/secrets | grep PASSWORD`
    content=`cat $configDir/alertmanager/alertmanager.yaml | sed -e "s,__USERNAME__,$username,g" -e "s,__PASSWORD__,$password,g"`
    kubectl create secret generic $secret --from-literal=alertmanager.yaml=$content --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "intelligence-secrets" ]; then
    token=`cat $secretDir/cmsmon-intelligence/secrets | grep TOKEN`
    content=`cat $configDir/cmsmon-intelligence/config.json | sed -e "s,__TOKEN__,$token,g"`
    kubectl create secret generic $secret --from-literal=config.json=$content --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "karma-secrets" ]; then
    files="--from-file=$configDir/karma/karma.yaml"
    if [ "$ha" == "ha1" ]; then
        files="--from-file=$configDir/karma/ha1/karma.yaml"
    else if [ "$ha" == "ha2" ]; then
        files="--from-file=$configDir/karma/ha2/karma.yaml"
    fi
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "promxy-secrets" ]; then
    files=`ls $configDir/promxy/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret $files --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "robot-secrets" ]; then
    files=`ls $secretDir/promxy/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "auth-secrets" ]; then
    files=`ls $secretDir/cmsmon-auth/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "cern-certificates" ]; then
    files=`ls $secretDir/CERN_CAs/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "alerts-secrets" ]; then
    files=`ls $secretDir/alerts/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "proxy-secrets" ]; then
    voms-proxy-init -voms cms -rfc -out /tmp/proxy
    files="--from-file=/tmp/proxy"
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "log-clustering-secrets" ]; then
    files=`ls $secretDir/log-clustering/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "es-wma-secrets" ]; then
    files=`ls $secretDir/es-exporter/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "hdfs-secrets" ]; then
    files=`ls $secretDir/kerberos/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
    files=`ls $secretDir/kerberos/ | awk '{ORS=" " ; print "--from-file="$1""}'`
else if [ "$secret" == "keytab-secrets" ]; then
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "krb5cc-secrets" ]; then
    files=`ls $secretDir/kerberos/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "nats-secrets" ]; then
    files=`ls $secretDir/nats/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "redash-secrets" ]; then
    files=`ls $secretDir/redash/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "rumble-secrets" ]; then
    files=`ls $secretDir/rumble/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "rucio-secrets" ]; then
    files=`ls $secretDir/rucio/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
else if [ "$secret" == "sqoop-secrets" ]; then
    files=`ls $secretDir/sqoop/ | awk '{ORS=" " ; print "--from-file="$1""}'`
    kubectl create secret generic $secret "$files" --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -
fi
kubectl describe secrets $secret -n $ns
