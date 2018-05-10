#!/bin/bash
if [ $# != 2 ]; then
    echo "make_ing_secret.sh <server.key> <server.crt>"
    exit 1
fi
skey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
cat > ing-secrets.yaml << EOF
apiVersion: v1
data:
  server.crt: $cert
  server.key: $skey
kind: Secret
metadata:
  name: ing-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/ing-secrets
type: Opaque
EOF
