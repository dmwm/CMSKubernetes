#!/bin/bash
if [ $# != 4 ]; then
    echo "make_confdb_secret.sh <robot_key> <robot_cert> <hmac> <confdbsecrets>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
confdbsecrets=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > confdb-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  confdb.txt: $confdbsecrets
kind: Secret
metadata:
  name: confdb-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/confdb-secrets
type: Opaque
EOF
