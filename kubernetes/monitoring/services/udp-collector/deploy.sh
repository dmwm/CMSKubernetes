#!/bin/bash
BASEDIR=$(dirname "$0")
kubectl create secret generic udp-secrets --from-file=secrets/udp/udp_server.json
kubectl apply -f udp-server.yaml --validate=false
