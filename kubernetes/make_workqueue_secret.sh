#!/bin/bash
if [ $# != 6 ]; then
    echo "make_workqueue_secret.sh <proxy> <robot_key> <robot_cert> <server_key> <server_cert> <hmac>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rkey=`cat $2 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $3 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $5 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $6 | base64 | awk '{ORS=""; print $0}'`
cat > workqueue-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  server.crt: $cert
  server.key: $skey
  hmac: $hmac
kind: Secret
metadata:
  name: workqueue-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/workqueue-secrets
type: Opaque
EOF
