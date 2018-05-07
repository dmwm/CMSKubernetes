#!/bin/bash
if [ $# != 4 ]; then
    echo "make_das_secret.sh <proxy> <server.key> <server.crt> <dasconfig.json>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $2 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $3 | base64 | awk '{ORS=""; print $0}'`
conf=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > das-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
  server.crt: $cert
  server.key: $skey
  dasconfig.json: $conf
kind: Secret
metadata:
  name: das-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/das-secrets
type: Opaque
EOF
