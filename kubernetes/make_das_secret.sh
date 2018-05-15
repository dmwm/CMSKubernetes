#!/bin/bash
if [ $# != 7 ]; then
    echo "make_das_secret.sh <proxy> <robot_key> <robot_crt> <server_key> <server_crt> <hmac> <dasconfig.json>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rkey=`cat $2 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $3 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $5 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $6 | base64 | awk '{ORS=""; print $0}'`
conf=`cat $7 | base64 | awk '{ORS=""; print $0}'`
cat > das-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  server.crt: $cert
  server.key: $skey
  hmac: $hmac
  dasconfig.json: $conf
kind: Secret
metadata:
  name: das-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/das-secrets
type: Opaque
EOF
