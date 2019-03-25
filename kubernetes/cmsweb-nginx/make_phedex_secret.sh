#!/bin/bash
if [ $# != 4 ]; then
    echo "make_phedex_secret.sh <robot_key> <robot_cert> <hmac> <phedexsecrets>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
phedexsecrets=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > phedex-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  phedex.txt: $phedexsecrets
kind: Secret
metadata:
  name: phedex-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/phedex-secrets
type: Opaque
EOF
