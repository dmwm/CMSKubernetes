#!/bin/bash
if [ $# != 1 ]; then
    echo "make_reqmgr_secret.sh <proxy>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
cat > reqmgr-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
kind: Secret
metadata:
  name: reqmgr-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/reqmgr-secrets
type: Opaque
EOF
