#!/bin/bash

cluster=tfaas
host=`openstack --os-project-name "CMS Webtools Mig" coe cluster show $cluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"

echo
echo "### label node"
clsname=`kubectl get nodes | tail -1 | awk '{print $1}'`
kubectl label node $clsname role=ingress --overwrite
kubectl get node -l role=ingress

echo
echo "### delete services"
kubectl delete -f tfaas.yaml
kubectl delete -f ing.yaml
kubectl apply -f tfaas.yaml --validate=false
kubectl apply -f ing.yaml --validate=false

sleep 2
echo
echo "### delete daemon ingress-traefik"
if [ -n "`kubectl get daemonset -n kube-system | grep ingress-traefik`" ]; then
    kubectl -n kube-system delete daemonset ingress-traefik
    kubectl -n kube-system delete svc ingress-traefik
fi
sleep 2
echo "### deploy traefik"
kubectl -n kube-system apply -f traefik.yaml --validate=false
