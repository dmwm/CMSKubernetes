#!/bin/bash
if [ $# != 4 ]; then
    echo "make_tfaas_secret.sh <robot_key> <robot_crt> <hmac> <tfaas-config.json>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
conf=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > tfaas-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  tfaas-config.json: $conf
kind: Secret
metadata:
  name: tfaas-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/tfaas-secrets
type: Opaque
EOF
