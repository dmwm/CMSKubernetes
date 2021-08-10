#!/bin/sh
host=https://cmsweb-test6.cern.ch/imagebot
host=https://cmsweb-testbed.cern.ch/imagebot
echo "obtain token"
token=`curl -v -s -X POST -H "content-type: application/json" -d '{"commit":"dad51084ea82ab2f6f573b6daa464ed0d7c23a1d", "namespace": "http", "repository": "vkuznet/httpgo", "image": "cmssw/httpgo", "tag":"00.00.01", "service":"httpgo"}' $host/token`
echo "new token $token"
echo ""
curl -v -s -X POST \
    -H "Authorization: Bearer $token" \
    -H "content-type: application/json" \
    -d '{"commit":"dad51084ea82ab2f6f573b6daa464ed0d7c23a1d", "namespace": "http", "repository": "vkuznet/httpgo", "image": "cmssw/httpgo",  "tag":"00.00.01", "service":"httpgo"}' $host/

