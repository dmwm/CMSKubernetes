#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -ne 3 ]; then
    echo "Usage: deploy-secrets.sh <namespace> <service-name> <path_to_configuration>"
    exit 1
fi

ns=$1
srv=$2
conf=$3

    # cmsweb configuration area
    echo "+++ configuration: $conf"
    echo "+++ cms service : $srv"
    echo "+++ namespaces   : $ns"

    if [ ! -d $conf/$srv ]; then
	echo "Unable to locate $conf/$srv, please provide proper directory structure like <configuration>/<service>/<files>"
  	exit 1
    fi


	cmdir=$conf/$srv
        osrv=$srv
        srv=`echo $srv | sed -e "s,_,,g"`
        files=""
        if [ -d $cmdir ] && [ -n "`ls $cmdir`" ]; then
        	for fname in $cmdir/*; do
                	files="$files --from-file=$fname"
                done
        fi
       echo $files

       kubectl create configmap ${srv}-config $files -n $ns

    echo
    echo "+++ list configmaps"
    kubectl get cm -n $ns
