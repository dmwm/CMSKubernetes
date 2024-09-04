#!/bin/bash
if [ $# -ne 3 ]; then
    echo "Extracts all secret files for given namespace and secret into provided output directory"
    echo "Usage: extract_secrets.sh <namespace> <secret> <output directory>"
    exit 1
fi

ns=$1
secret=$2
odir=$3
files=`kubectl describe secrets -n $1 $2 | grep bytes | awk '{print $1}' | sed -e "s/://g"`
for sfile in $files; do
    echo "extract $sfile"
    kubectl get secrets -n $ns $secret -o yaml | grep "  $sfile" | head -1 | awk '{print $2}' | base64 -d > $odir/$sfile
done
