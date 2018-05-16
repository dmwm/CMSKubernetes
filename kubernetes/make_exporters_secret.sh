#!/bin/bash
if [ $# != 2 ]; then
    echo "make_exporters_secret.sh <robot_key> <robot_crt>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
cat > exporters-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
kind: Secret
metadata:
  name: exporters-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/couchdb-secrets
type: Opaque
EOF
