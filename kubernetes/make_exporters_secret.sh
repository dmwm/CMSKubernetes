#!/bin/bash
if [ $# != 1 ]; then
    echo "make_exporters_secret.sh <proxy>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
cat > exporters-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
kind: Secret
metadata:
  name: exporters-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/exporters-secrets
type: Opaque
EOF
