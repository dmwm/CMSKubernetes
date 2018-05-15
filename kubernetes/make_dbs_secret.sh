#!/bin/bash
if [ $# != 9 ]; then
    echo "make_dbs_secret.sh <proxy> <robot_key> <robot_cert< <server_key> <server_crt> <hmac> <dbsconfig.json> <dbfile> <dbssecrets>"
    exit 1
fi
proxy=`cat $1 | base64 | awk '{ORS=""; print $0}'`
rkey=`cat $2 | base64 | awk '{ORS=""; print $0}'`
rcert=`cat $3 | base64 | awk '{ORS=""; print $0}'`
skey=`cat $4 | base64 | awk '{ORS=""; print $0}'`
cert=`cat $5 | base64 | awk '{ORS=""; print $0}'`
hmac=`cat $6 | base64 | awk '{ORS=""; print $0}'`
conf=`cat $7 | base64 | awk '{ORS=""; print $0}'`
dbfile=`cat $8 | base64 | awk '{ORS=""; print $0}'`
dbssecrets=`cat $9 | base64 | awk '{ORS=""; print $0}'`
cat > dbs-secrets.yaml << EOF
apiVersion: v1
data:
  proxy: $proxy
  robotcert.pem: $rcert
  robotkey.pem: $rkey
  server.crt: $cert
  server.key: $skey
  hmac: $hmac
  dbsconfig.json: $conf
  dbfile: $dbfile
  DBSSecrets.py: $dbssecrets
kind: Secret
metadata:
  name: dbs-secrets
  namespace: default
  selfLink: /api/v1/namespaces/default/secrets/dbs-secrets
type: Opaque
EOF
