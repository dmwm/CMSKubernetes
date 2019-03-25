#!/bin/bash
if [ $# != 4 ]; then
    echo "make_dbsmig_secret.sh <robot_key> <robot_cert> <hmac> <dbsmigsecrets>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
dbsmigsecrets=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > dbsmig-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  dbsmigSecrets.py: $dbsmigsecrets
kind: Secret
metadata:
  name: dbsmig-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/dbsmig-secrets
type: Opaque
EOF
