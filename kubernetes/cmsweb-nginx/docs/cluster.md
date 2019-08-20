### How to create k8s cluster
Each cluster operates in its own namespace. To switch between namespaces you
can either setup
```
# example of setting up project name
export OS_PROJECT_NAME="CMS Web"
```
or use appropriate option to openstack command
```
openstack --os-porject-name "CMS Web"
```
From now on we'll assume that you'll setup appropriate `OS_PROJECT_NAME`
environment.

Create new cluster by login to `lxplus-cloud.cern.ch` and execute the
following command (use one of them, they are listed as an example)

```
# create new cluster
openstack coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true

# create new cluster with specific flavor and number of nodes
openstack coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true --flavor m2.2xlarge --node-count 2

openstack coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.14.1-1 --labels cern_enabled=True,kube_tag=v1.14.1,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true,manila_enabled=True,manila_version=v0.3.0,heat_container_agent_tag=stein-dev-1 --flavor m2.2xlarge --node-count 2

openstack coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-2 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true,manila_enabled=True,manila_version=v0.3.0,heat_container_agent_tag=stein-dev-1 --flavor m2.2xlarge --node-count 2

# large template
openstack coe cluster template create cmsweb-template-2xlarge --labels influx_grafana_dashboard_enabled="true" --labels ingress_controller="nginx" --labels tiller_enabled=true --labels kube_csi_enabled="true" --labels kube_csi_version="v0.3.2" --labels kube_tag="v1.13.3-12" --labels container_infra_prefix="gitlab-registry.cern.ch/cloud/atomic-system-containers/" --labels manila_enabled="true" --labels cgroup_driver="cgroupfs" --labels cephfs_csi_enabled="true" --labels cvmfs_csi_version="v0.3.0" --labels admission_control_list="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority" --labels flannel_backend="vxlan" --labels manila_version="v0.3.0" --labels cvmfs_csi_enabled="true" --labels cvmfs_tag="qa" --labels cephfs_csi_version="v0.3.0" --labels cern_enabled="true" --coe kubernetes --image 26666ca8-bda9-4356-982f-4a92845ec361 --external-network CERN_NETWORK --fixed-network CERN_NETWORK --network-driver flannel --dns-nameserver 137.138.17.5 --flavor m2.2xlarge --master-flavor m2.medium --docker-storage-driver overlay2 --server-type vm

# create new template
openstack coe cluster template create cmsweb-template-medium --labels influx_grafana_dashboard_enabled="true" --labels ingress_controller="nginx" --labels tiller_enabled=true --labels kube_csi_enabled="true" --labels kube_csi_version="v0.3.2" --labels kube_tag="v1.13.3-12" --labels container_infra_prefix="gitlab-registry.cern.ch/cloud/atomic-system-containers/" --labels manila_enabled="true" --labels cgroup_driver="cgroupfs" --labels cephfs_csi_enabled="true" --labels cvmfs_csi_version="v0.3.0" --labels admission_control_list="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority" --labels flannel_backend="vxlan" --labels manila_version="v0.3.0" --labels cvmfs_csi_enabled="true" --labels cvmfs_tag="qa" --labels cephfs_csi_version="v0.3.0" --labels cern_enabled="true" --coe kubernetes --image 26666ca8-bda9-4356-982f-4a92845ec361 --external-network CERN_NETWORK --fixed-network CERN_NETWORK --network-driver flannel --dns-nameserver 137.138.17.5 --flavor m2.medium --master-flavor m2.medium --docker-storage-driver overlay2 --server-type vm

# manage templates
openstack coe cluster template list
openstack coe cluster template delete 89073ecc-d416-452f-84a9-278612b63d1e
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-2xlarge cmsweb

# update cluster, to use 4 nodes
openstack coe cluster update cmsweb replace node_count=4
```

You will need to wait once cluster is created. You may verify its existence
with this command:
```
openstack --os-project-name "CMS Webtools Mig" coe cluster list
# it should have CREATE_COMPLETE status
```

Once cluster is created we need to perform one-time operation to get pem files
and config for it. Just do:
```
# remove previous pem files and configuration
rm *.pem config
# create new pem files and configuration
$(openstack coe cluster config cmsweb)
```

Create new DNS alias at `https://webservices.web.cern.ch/webservices/`
using our k8s node name which we can obtain via `kubectl get node` command.
Use this name with .cern.ch suffix to create a DNS alias we need, e.g.
`cmsweb`. The new DNS alias will be accessible as `<aliasName>.web.cern.ch`
