#!/bin/bash
BASEDIR=$(dirname "$0")
SECRET_FILE="$BASEDIR/secrets/udp/udp_server.json"

if [ ! -f "$SECRET_FILE" ]; then
  echo "Error: $SECRET_FILE not found."
  exit 1
fi

kubectl create secret generic udp-secrets --from-file="$SECRET_FILE"
kubectl apply -f udp-server.yaml --validate=false