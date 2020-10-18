#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -ne 2 ]; then
    echo "Usage: deploy-srv.sh <srv> <imagetag>"
    exit 1
fi

srv=$1
itag=$2
tmpDir=/tmp/$USER/k8s/srv

# use tmp area to store service file
if [ -d $tmpDir ]; then
    rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir
curl -ksLO https://raw.githubusercontent.com/dmwm/CMSKubernetes/master/kubernetes/cmsweb/services/$srv.yaml

# check that service file has imagetag
if [ -z "`grep imagetag $srv.yaml`" ]; then
    echo "unable to locate imagetag in $srv.yaml"
    exit 1
fi

# replace imagetag with real value and deploy new service
cat $srv.yaml | sed -e "s, #imagetag,:$itag,g" | \
    kubectl apply -f -

# return to original directory
cd -
