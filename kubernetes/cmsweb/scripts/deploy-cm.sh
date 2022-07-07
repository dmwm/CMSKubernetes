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

tmpDir=/tmp/$USER/sops
if [ -d $tmpDir ]; then
   rm -rf $tmpDir
fi
mkdir -p $tmpDir
cd $tmpDir

if [ -z "`command -v sops`" ]; then
  # download soap in tmp area
  wget -O sops https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux.amd64
  chmod u+x sops
  mkdir -p $HOME/bin
  echo "Download and install sops under $HOME/bin"
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


    sopskey=$SOPS_AGE_KEY_FILE
    kubectl get secrets $ns-keys-secrets -n $ns --template="{{index .data \"$ns-keys.txt\" | base64decode}}" > "$tmpDir/$ns-keys.txt"
    export SOPS_AGE_KEY_FILE="$tmpDir/$ns-keys.txt"
    echo "Key file: $SOPS_AGE_KEY_FILE"

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
    rm -rf $tmpDir
