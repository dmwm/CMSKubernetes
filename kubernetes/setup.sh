#!/bin/bash

if [ $# -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]; then
    echo "Usage: setup.sh <cluster name>"
    exit 0
fi

#wdir=/afs/cern.ch/user/v/valya/private/CMSKubernetes/kubernetes
wdir=$PWD
cluster=$1
export KUBECONFIG=$wdir/$cluster/config
host=`openstack --os-project-name "CMS Webtools Mig" coe cluster show $cluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"
