#!/bin/bash
# helper script to deploy given service with given tag to k8s infrastructure

if [ $# -ne 3 ]; then
    echo "Usage: deploy-cm.sh <namespace> <service-name> <path_to_configuration>"
    exit 1
fi

cluster_name=`kubectl config get-clusters | grep -v NAME`

ns=$1
srv=$2
conf=$3
secretref=${4:-https://openstack.cern.ch:9311/v1/secrets/35145b52-18af-47a3-90d0-1861c51a9c65}

if [[ "$cluster_name" == cmsweb-test[1-9]* ]] ; then
   secretref="https://openstack.cern.ch:9311/v1/secrets/010bee01-f50f-40e6-b954-e24eae51d8d3"
fi

if [ -z "`command -v sops`" ]; then
  # download soap in tmp area
  tmpDir=/tmp/$USER/sops
  if [ -d $tmpDir ]; then
    rm -rf $tmpDir
  fi
  mkdir -p $tmpDir
  cd $tmpDir
  wget -O sops https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux.amd64
  chmod u+x sops
  mkdir -p $HOME/bin
  cp ./sops $HOME/bin
fi

    # cmsweb configuration area
    echo "+++ cluster name: $cluster_name"
    echo "+++ configuration: $conf"
    echo "+++ cms service : $srv"
    echo "+++ namespaces   : $ns"

    if [ ! -d $conf/$srv ]; then
	echo "Unable to locate $conf/$srv, please provide proper directory structure like <configuration>/<service>/<files>"
  	exit 1
    fi

    mkdir -p $HOME/.openstack/config/sops/age
    if [ ! -f $HOME/.openstack/config/sops/age/openstack-keys.txt ]; then
      openstack secret get $secretref --payload_content_type application/octet-stream --file $HOME/.openstack/config/sops/age/openstack-keys.txt
    fi
    sopskey=$SOPS_AGE_KEY_FILE
    export SOPS_AGE_KEY_FILE="$HOME/.openstack/config/sops/age/openstack-keys.txt"

	cmdir=$conf/$srv
        osrv=$srv
        srv=`echo $srv | sed -e "s,_,,g"`
        files=""
        if [ -d $cmdir ] && [ -n "`ls $cmdir`" ]; then
        	for fname in $cmdir/*; do
                   if [[ $fname == *.encrypted ]]; then
                       sops -d $fname > $cmdir/$(basename $fname .encrypted)
                       fname=$cmdir/$(basename $fname .encrypted)
                       echo "Decrypted file $fname"
                   fi
                   if [[ ! $files == *$fname* ]]; then
                      files="$files --from-file=$fname"
                   fi
                done
        fi
       echo $files
       kubectl delete cm ${srv}-config -n $ns
       kubectl create configmap ${srv}-config $files -n $ns

       export SOPS_AGE_KEY_FILE=$sopskey

    echo
    echo "+++ list configmaps"
    kubectl get cm -n $ns
