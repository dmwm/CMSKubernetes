#! /bin/bash

export NAME=cmsruciosync
export MINIONS=2
export MINIONSIZE=m2.large

#openstack coe cluster create $NAME --keypair lxplus --os-project-name CMSRucio --node-count $MINIONS --cluster-template kubernetes-1.14.6-1 --labels admission_control_list="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority",cern_enabled=True,kube_tag=v1.14.6,kube_csi_enabled=True,kube_csi_version=cern-csi-1.0-1,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,cvmfs_csi_enabled=False,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true,manila_enabled=True,manila_version=v0.3.0,heat_container_agent_tag=stein-dev-1 --master-flavor m2.small  --flavor $MINIONSIZE  
openstack coe cluster create $NAME --keypair lxplus --os-project-name CMSRucio --node-count $MINIONS --cluster-template kubernetes-1.14.6-1 --labels ingress_controller=nginx,cern_enabled=True --master-flavor m2.small  --flavor $MINIONSIZE  



