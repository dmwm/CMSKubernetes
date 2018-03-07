#!/bin/bash
if [ $# != 3 ]; then
    echo "make_das_secret.sh <proxy> <server.key> <server.crt>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $2 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $3 | base64 | awk '{ORS=""; print $0}'`
cat > das-secret.yaml << EOF
apiVersion: v1
data:
  das-proxy: $proxy
  server.crt: $cert
  server.key: $skey
kind: Secret
metadata:
  name: das-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/das-secrets
type: Opaque
EOF
