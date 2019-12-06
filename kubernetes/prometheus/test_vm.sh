#!/bin/bash
url="http://cms-prometheus.cern.ch"
url="http://cms-monitoring.cern.ch"
purl=${url}:30422/api/put
rurl=${url}:30428/api/v1/export
echo "put data into $purl"
curl -H 'Content-Type: application/json' -d '{"metric":"cms.dbs.exitCode", "value":8021, "tags":{"site":"T2_US", "task":"test", "log":"/path/file.log"}}' "$purl"
echo "get data from $rurl"
curl -G "$rurl" -d 'match[]=cms.dbs.exitCode'
