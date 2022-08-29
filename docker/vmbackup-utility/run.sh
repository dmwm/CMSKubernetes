#!/bin/bash

NOW=$(date +"%Y/%m/%d/%H:%M")

if [[ "$HOSTNAME" == "victoria-metrics-long"* ]] ; then

  snapshot=`curl http://cms-monitoring-agg:31428/snapshot/create | jq -r '.snapshot'`
  if [ -z "$snapshot" ]
    then
      echo "Snapshot not found"
    else
    AWS_DEFAULT_REGION=CERN  /data/VictoriaMetrics/bin/vmbackup -storageDataPath=/tsdb -snapshotName=$snapshot -credsFilePath=/etc/secrets/s3-keys -customS3Endpoint=https://s3.cern.ch -dst=s3://cms-monitoring/vmbackup-long/$NOW
  fi
else
  snapshot=`curl http://cms-monitoring-agg:30428/snapshot/create | jq -r '.snapshot'`
  if [ -z "$snapshot" ]
    then
      echo "Snapshot not found"
    else
    AWS_DEFAULT_REGION=CERN  /data/VictoriaMetrics/bin/vmbackup -storageDataPath=/tsdb -snapshotName=$snapshot -credsFilePath=/etc/secrets/s3-keys -customS3Endpoint=https://s3.cern.ch -dst=s3://cms-monitoring/vmbackup/$NOW
  fi
fi

