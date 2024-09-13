#!/bin/bash

# Check if the namespace is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

namespace=$1

# Get all pods in the namespace that are stuck in "Terminating" state
echo "Finding pods stuck in 'Terminating' state in namespace: $namespace..."

kubectl get pods -n "$namespace" -o json | jq -r '.items[] | select(.metadata.deletionTimestamp != null) | .metadata.name' | while read pod; do
    echo "Force deleting pod: $pod in namespace: $namespace"
    kubectl delete pod "$pod" -n "$namespace" --grace-period=0 --force
done

