#! /bin/bash

export PROJECT=`helm list -q ruciod`
echo "Setting secrets for helm in $PROJECT"
mkdir /tmp/reaper-certs
cp /etc/grid-security/certificates/*.0 /tmp/reaper-certs/
kubectl create secret generic $PROJECT-rucio-ca-bundle-reaper --from-file=/tmp/certs/
rm -rf /tmp/reaper-certs
