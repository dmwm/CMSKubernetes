#!/bin/bash
if [ $# != 3 ]; then
    echo "make_acdcserver_secret.sh <robot_key> <robot_crt> <hmac>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
cat > acdcserver-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
kind: Secret
metadata:
  name: acdcserver-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/acdcserver-secrets
type: Opaque
EOF
