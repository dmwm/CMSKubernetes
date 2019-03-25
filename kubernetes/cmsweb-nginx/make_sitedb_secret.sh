#!/bin/bash
if [ $# != 4 ]; then
    echo "make_sitedb_secret.sh <robot_key> <robot_cert> <hmac> <sitedbsecrets>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
sitedbsecrets=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > sitedb-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  sitedb.txt: $sitedbsecrets
kind: Secret
metadata:
  name: sitedb-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/sitedb-secrets
type: Opaque
EOF
