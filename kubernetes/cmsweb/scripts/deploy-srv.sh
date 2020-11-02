#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -ne 3 ]; then
    echo "Usage: deploy-srv.sh <srv> <imagetag> <env (prod or preprod or test)>"
    exit 1
fi

srv=$1
cmsweb_image_tag=:$2
env=$3
cmsweb_env=k8s-$3
cmsweb_log=logs-cephfs-claim-$3



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
if [ "$cmsweb_env" == "k8s-prod" ] || [ "$cmsweb_env" == "k8s-preprod" ]; then

	cat $srv.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" |  sed -e "s,logs-cephfs-claim,$cmsweb_log,g" | sed -e "s, #imagetag,$cmsweb_image_tag,g" | sed -e "s,k8s #k8s#,$cmsweb_env,g" | kubectl apply -f -

else 

	cat $srv.yaml | sed -e "s, #imagetag,$cmsweb_image_tag,g" | kubectl apply -f -
fi


# return to original directory
cd -
