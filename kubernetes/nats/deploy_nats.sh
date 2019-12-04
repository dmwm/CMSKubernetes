#!/bin/bash
set -e  # exit script if error occurs

echo "Add ingress controller"
kubectl get nodes

echo "Initialize cms-nats alias for our minions"
kubectl get nodes | grep minion | awk 'BEGIN{i=0}{print "openstack server set --property landb-alias=cms-nats--load-"i"- "$1""; i++}'

echo "Wait for cms-nats landb entry to appear..., press CTRL+C when you see them"
watch -d host cms-nats.cern.ch

echo "Deploy NATS"
kubectl apply -f https://github.com/nats-io/nats-operator/releases/latest/download/00-prereqs.yaml
kubectl apply -f https://github.com/nats-io/nats-operator/releases/latest/download/10-deployment.yaml
kubectl get crd

echo "Let's watch when nats crd's are created, invoke CTRL+C when you see them"
watch -d kubectl get crd | grep nats

echo "create nats-clients-auth secret"
if [ -n "`kubectl get secrets | grep nats-clients-auth`" ]; then
    kubectl delete secret nats-clients-auth
fi
if [ -f clients-auth.json ]; then
    kubectl create secret generic nats-clients-auth --from-file=clients-auth.json
else
    echo "Unable to local clients-auth.json file"
    exit 1
fi
if [ -f ca.pem ] && [ -f server-key.pem ] && [ -f server.pem ]; then
    kubectl create secret generic nats-clients-tls \
        --from-file=secrets/nats-cluster/ca.pem \
        --from-file=secrets/nats-cluster/server-key.pem \
        --from-file=secrets/nats-cluster/server.pem \
        --from-file=secrets/nats/CMS/CMS.jwt
fi

echo "deploy nats-cluster"
kubectl apply -f nats-cluster.yaml --validate=false

# redeploy the configuration with NSC operator and resolver
#kubectl create secret generic nats-nsc-secrets --from-file=nats-nsc.tar.gz
#kubectl delete secret nats-cluster
#kubectl create secret generic nats-cluster --from-file=nats.conf
# this will force nats cluster to be reloaded with new configuration file

echo "Now let's see if nats-cluster are Running..., press CTRL+C when you see them"
watch -d kubectl get nats --all-namespaces
