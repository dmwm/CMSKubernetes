#! /bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [[ $# -ne 1 ]]; then
    echo "Usage: deploy.sh ENVNAME"
    echo " ENVNAME=(prod|testbed|test2|test11|test12)"
    exit 1
fi
desired_cluster=$1
# make sure that your current context points to the desired cluster
current_cluster=$(kubectl config view -o json | jq '.["current-context"] as $context | .["contexts"][] | select(.name | contains($context))| .context.cluster')
if [[ $current_cluster =~ $desired_cluster ]]; then 
  echo "deploying to $desired_cluster"; 
  helm template crabserver . -f values.yaml -f values-$desired_cluster.yaml | kubectl -n crab apply -f -
else 
  echo "wrong cluster: your are connected to $current_cluster"; 
fi

