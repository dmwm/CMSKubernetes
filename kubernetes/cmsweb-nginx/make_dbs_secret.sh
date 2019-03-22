#!/bin/bash
if [ $# != 4 ]; then
    echo "make_dbs_secret.sh <robot_key> <robot_cert> <hmac> <dbssecrets>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
dbssecrets=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cat > dbs-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  DBSSecrets.py: $dbssecrets
kind: Secret
metadata:
  name: dbs-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/dbs-secrets
type: Opaque
EOF
