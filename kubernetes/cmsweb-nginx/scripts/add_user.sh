#!/bin/bash
if [ $# -eq 1 ]; then
    user=$1
    kubectl create rolebinding ${user}-edit --clusterrole=edit --user $user --namespace=default
    kubectl get rolebinding
else
    echo "Usage: add_user.sh <user_name>"
fi
