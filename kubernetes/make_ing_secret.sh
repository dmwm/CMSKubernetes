#!/bin/bash
if [ $# != 4 ]; then
    echo "make_ing_secret.sh <robot_key> <robot_crt> <server_key> <server_crt>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $3 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > ing-secrets.yaml << EOF
apiVersion: v1
ata:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  server.crt: $cert
  server.key: $skey
kind: Secret
metadata:
  name: ing-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/ing-secrets
type: Opaque
EOF
