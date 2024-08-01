#! /bin/bash
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# hash table of clusters nickname-name:
declare -A cluster_map=([prod]=prod)
cluster_map[prod]=k8s-prodsrv
cluster_map[preprod]=k8s-prodsrv-v1.22.9
cluster_map[testbed]=testbed
cluster_map[test2]=test2
cluster_map[test11]=test11
cluster_map[test12]=test12
if [[ $# -ne 1 ]]; then
    echo "Usage: deploy.sh ENVNAME"
    echo " ENVNAME=(prod|preprod|testbed|test2|test11|test12)"
    exit 1
fi
desired_cluster="${cluster_map[$1]}"

# make sure that your current context points to the desired cluster
current_cluster=$(kubectl config view -o json | jq '.["current-context"] as $context | .["contexts"][] | select(.name | contains($context))| .context.cluster')

if [[ $current_cluster =~ $desired_cluster ]]; then 
  echo "deploying to $desired_cluster"; 
  helm template crabserver . -f values.yaml -f values-${1}-pypi.yaml | kubectl -n crab apply -f -
else 
  echo "wrong cluster: your are connected to $current_cluster"; 
fi

