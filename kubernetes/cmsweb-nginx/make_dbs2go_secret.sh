#!/bin/bash
if [ $# != 5 ]; then
    echo "make_dbs_secret.sh <robot_key> <robot_cert> <hmac> <dbsconfig.json> <dbfile>"
    exit 1
fi
rkey=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $2 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $3 | base64 | awk '{ORS=""; print $0}'`
conf=`cat $4 | base64 | awk '{ORS=""; print $0}'`
dbfile=`cat $5 | base64 | awk '{ORS=""; print $0}'`
cat > dbs2go-secrets.yaml << EOF
apiVersion: v1
data:
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  hmac: $hmac
  dbsconfig.json: $conf
  dbfile: $dbfile
kind: Secret
metadata:
  name: dbs2go-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/dbs-secrets
type: Opaque
EOF
