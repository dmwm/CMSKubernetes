#! /bin/bash
set -euo pipefail

ENVNAME=$1

# hash table of clusters nickname-name:
declare -A cluster_map=([prod]=prod)
cluster_map[prod]=k8s-prodsrv
cluster_map[preprod]=k8s-prodsrv-v1.22.9
cluster_map[testbed]=testbed
cluster_map[test2]=test2
cluster_map[test11]=test11
cluster_map[test12]=test12
cluster_map[test14]=test14

declare -A valuefile_map=([prod]=prod)
valuefile_map[prod]=values-prod.yaml
valuefile_map[preprod]=values-preprod.yaml
valuefile_map[testbed]=values-testbed.yaml
valuefile_map[test2]=values-testx.yaml
valuefile_map[test11]=values-testx.yaml
valuefile_map[test12]=values-testx.yaml
valuefile_map[test14]=values-testx.yaml

if [[ $# -ne 1 ]]; then
    echo "Usage: deploy.sh ENVNAME"
    echo " ENVNAME=(prod|preprod|testbed|test2|test11|test12|test14)"
    exit 1
fi
desired_cluster="${cluster_map[$ENVNAME]}"
valuefile="${valuefile_map[$ENVNAME]}"

# make sure that your current context points to the desired cluster
current_cluster=$(kubectl config view -o json | jq '.["current-context"] as $context | .["contexts"][] | select(.name | contains($context))| .context.cluster')
set -x
if [[ $current_cluster =~ $desired_cluster ]]; then
  echo "deploying to $desired_cluster";
  helm template crabserver . -f values.yaml -f "${valuefile}" | kubectl -n crab apply -f -
else
  echo "Error: wrong cluster. your are connected to $current_cluster";
fi
