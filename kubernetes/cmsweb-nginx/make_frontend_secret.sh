#!/bin/bash
if [ $# != 5 ]; then
    echo "make_frontend_secret.sh <robot_key> <robot_cert> <hostkey.pem> <hostcert.pem> <hmac>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $5 | base64 | awk '{ORS=""; print $0}'`
cat > frontend-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hostcert.pem: $cert
  hostkey.pem: $skey
  hmac: $hmac
kind: Secret
metadata:
  name: frontend-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/frontend-secrets
type: Opaque
EOF
