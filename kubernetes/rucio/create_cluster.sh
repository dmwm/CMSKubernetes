#! /bin/bash

export NAME=cmsruciodev2
export MINIONS=5
export MINIONSIZE=m2.medium

openstack coe cluster create $NAME --keypair lxplus --os-project-name CMSRucio --node-count $MINIONS --cluster-template cmsrucio-1909 --master-flavor m2.medium --flavor $MINIONSIZE  

# These are good settings for the sync cluster. 

export NAME=cmsruciosync
export MINIONS=2
export MINIONSIZE=m2.large

openstack coe cluster create $NAME --keypair lxplus --os-project-name CMSRucio --node-count $MINIONS --cluster-template cmsrucio-1909 --master-flavor m2.small  --flavor $MINIONSIZE  




openstack coe cluster create --cluster-template kubernetes-alpha \
    --labels influx_grafana_dashboard_enabled=true,kube_csi_enabled=True,kube_tag=v1.10.3-5,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,cephfs_csi_enabled=True,flannel_backend=vxlan,cvmfs_csi_enabled=True,ingress_controller=traefik,manila_enabled=True,manila_version=v0.2.1,logging_type=http,logging_http_destination='http://monit-logs.cern.ch:10012/',logging_producer=cms-rucio,logging_include_internal=true\
    --node-count 1 --keypair lxplus logtest


