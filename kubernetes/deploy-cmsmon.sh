#!/bin/bash

# 1. create new cluster
# - ssh lxplus-cloud.cern.ch
# - openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsmon --keypair cloud --cluster-template kubernetes-preview --labels cern_enabled=True,kube_csi_enabled=True,kube_tag=v1.10.1,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=traefik
# - wait once it is created
# - openstack --os-project-name "CMS Webtools Mig" coe cluster list
# 2. run deploy-cmsmon.sh script which outlines all steps we need
# - verify that it is running via
# - kubectl get pods
# - kubectl get pods -n kube-system
# - kubectl get svc
# 3. create new DNS alias at https://webservices.web.cern.ch/webservices/
# - get k8s node name
# - kubectl get node
# - register it in webservices
# 4. check that new service is running
# - curl http://cmsmon.web.cern.ch

cluster=cmsmon
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
kubectl delete -f cmsmon.yaml
kubectl delete -f ing-cmsmon.yaml
kubectl apply -f cmsmon.yaml --validate=false
kubectl apply -f ing-cmsmon.yaml --validate=false

sleep 2
echo
echo "### delete daemon ingress-traefik"
if [ -n "`kubectl get daemonset -n kube-system | grep ingress-traefik`" ]; then
    kubectl -n kube-system delete daemonset ingress-traefik
    kubectl -n kube-system delete svc ingress-traefik
fi
sleep 2
echo "### deploy traefik"
kubectl -n kube-system apply -f traefik-cmsmon.yaml --validate=false
