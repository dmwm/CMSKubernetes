#! /bin/bash

export $NAME=ewvtest
export $MINIONS=2

openstack coe cluster create $NAME --keypair lxplus --os-project-name CMSRucio --node-count $MINIONS --cluster-template kubernetes-1.14.1-1 --labels cern_enabled=True,kube_tag=v1.14.1,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true,manila_enabled=True,manila_version=v0.3.0,heat_container_agent_tag=stein-dev-1 --master-flavor m2.small    



