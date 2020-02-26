#!/bin/bash
namespace=${OS_PROJECT_NAME:-"CMS Web"}
tmpl=cmsweb-template-dev-`date +%Y%m%d`
usage="create_templates.sh <tmpl_name, if not provided will use $tmpl>"
if [ "$1" != "" ]; then
    if [ "$1" == "-help" ] || [ "$1" == "-h" ]; then
        echo $usage
        exit 0
    fi
    tmpl=$1
fi
echo "Creating: $tmpl"

# large template
openstack \
    --os-project-name "$namespace" coe cluster template create $tmpl \
    --labels admission_control_list="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority" \
    --labels calico_ipv4pool="10.100.0.0/16" \
    --labels calico_ipv4pool_ipip="CrossSubnet" \
    --labels cephfs_csi_enabled="true" \
    --labels cephfs_csi_version="cern-csi-1.0-2" \
    --labels cern_enabled="true" \
    --labels cern_tag="v0.5.0" \
    --labels cgroup_driver="cgroupfs" \
    --labels cloud_provider_tag="v1.17.0" \
    --labels container_infra_prefix="gitlab-registry.cern.ch/cloud/atomic-system-containers/" \
    --labels cvmfs_csi_enabled="true" \
    --labels cvmfs_csi_version="v1.0.0" \
    --labels cvmfs_tag="qa" \
    --labels etcd_tag=3.3.17 \
    --labels heapster_enabled="false" \
    --labels heat_container_agent_tag=train-stable-1 \
    --labels influx_grafana_dashboard_enabled="false" \
    --labels ingress_controller="nginx" \
    --labels keystone_auth_enabled="true" \
    --labels kube_csi_enabled="true" \
    --labels kube_csi_version="cern-csi-1.0-2" \
    --labels kube_tag="v1.17.2" \
    --labels kubeapi_options="--feature-gates=CSINodeInfo=true,CSIDriverRegistry=true" \
    --labels kubecontroller_options="--feature-gates=CSINodeInfo=true,CSIDriverRegistry=true" \
    --labels kubelet_options="--feature-gates=CSINodeInfo=true,CSIDriverRegistry=true" \
    --labels logging_http_destination="http://monit-logs.cern.ch:10012/" \
    --labels logging_include_internal="true" \
    --labels logging_producer="cmswebk8s" \
    --labels logging_type="http" \
    --labels manila_enabled="true" \
    --labels manila_version="v0.3.0" \
    --labels metrics_server_enabled="true" \
    --labels tiller_enabled="true" \
    --labels use_podman="true" \
    --coe kubernetes \
    --image 5b338766-0fbf-47fa-9d9a-8f9543be9729 \
    --external-network CERN_NETWORK \
    --fixed-network CERN_NETWORK \
    --network-driver calico \
    --dns-nameserver 137.138.17.5 \
    --flavor m2.medium \
    --master-flavor m2.medium \
    --docker-storage-driver overlay2 \
    --server-type vm

# list tempaltes
openstack --os-project-name "$namespace" coe cluster template list
