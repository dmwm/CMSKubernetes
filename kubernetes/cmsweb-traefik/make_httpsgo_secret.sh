#!/bin/bash
if [ $# != 1 ]; then
    echo "make_httpsgo_secret.sh <httpsgoconfig.json>"
    exit 1
fi
conf=`cat $1 | base64 | awk '{ORS=""; print $0}'`
cat > httpsgo-secrets.yaml << EOF
apiVersion: v1
data:
  httpsgoconfig.json: $conf
kind: Secret
metadata:
  name: httpsgo-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/httpsgo-secrets
type: Opaque
EOF
