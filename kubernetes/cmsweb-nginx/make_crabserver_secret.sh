#!/bin/bash
if [ $# != 3 ]; then
    echo "make_crabserver_secret.sh <robot_key> <robot_cert> <hmac>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
cat > crabserver-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
kind: Secret
metadata:
  name: crabserver-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/crabserver-secrets
type: Opaque
EOF
