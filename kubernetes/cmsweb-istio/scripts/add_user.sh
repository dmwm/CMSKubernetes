#!/bin/bash
if [ $# -eq 2 ]; then
    user=$1
    ns=$2
    kubectl create rolebinding ${user}-manage-$ns --clusterrole=edit --user $user --namespace=$ns
    kubectl get rolebinding --all-namespaces
else
    echo "Usage: add_user.sh <user_name> <namespace>"
fi
