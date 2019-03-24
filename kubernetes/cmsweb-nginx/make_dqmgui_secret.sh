#!/bin/bash
if [ $# != 3 ]; then
    echo "make_dqmgui_secret.sh <robot_key> <robot_cert> <hmac>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
cat > dqmgui-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
kind: Secret
metadata:
  name: dqmgui-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/dqmgui-secrets
type: Opaque
EOF
