#!/bin/bash
if [ $# != 2 ]; then
    echo "make_reqmon_secret.sh <proxy> <hmac>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $2 | base64 | awk '{ORS=""; print $0}'`
cat > reqmon-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
  hmac: $hmac
kind: Secret
metadata:
  name: reqmon-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/reqmon-secrets
type: Opaque
EOF
