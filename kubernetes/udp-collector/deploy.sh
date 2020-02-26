#!/bin/bash
BASEDIR=$(dirname "$0")
node=`kubectl get node | egrep -v "NAME|master" | awk '{print $1}'`
kubectl label node $node role=ingress --overwrite
kubectl create secret generic udp-secrets --from-file=secrets/udp/udp_server.json
kubectl apply -f udp-server.yaml --validate=false
kubectl apply -f ingress.yaml
$BASEDIR/adjust_nginx.sh
