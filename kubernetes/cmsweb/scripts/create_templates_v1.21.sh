#!/bin/bash
namespace=${OS_PROJECT_NAME:-"CMS Web"}
tmpl=cmsweb-template-v-1.21.1-1-`date +%Y%m%d`
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
	--labels admission_control_list="ExtendedResourceToleration,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority" \
	--labels autoscaler_tag="v1.21.0-cern.0" \
	--labels calico_ipv4pool="10.100.0.0/16" \
	--labels calico_ipv4pool_ipip="CrossSubnet" \
	--labels calico_tag="v3.13.2" \
	--labels cephfs_csi_enabled="true" \
	--labels cephfs_csi_version="cern-csi-1.0-3" \
	--labels cern_enabled="true" \
	--labels cern_chart_version="0.8.3" \
	--labels cern_chart_enabled="true" \
	--labels cern_tag="v0.5.0" \
	--labels cgroup_driver="cgroupfs" \
	--labels cloud_provider_tag="v1.20.0-1" \
	--labels coredns_tag="1.6.6" \
	--labels container_infra_prefix="registry.cern.ch/magnum/" \
	--labels container_runtime="containerd" \
	--labels containerd_tarball_sha256="2697a342e3477c211ab48313e259fd7e32ad1f5ded19320e6a559f50a82bff3d" \
	--labels containerd_tarball_url="https://s3.cern.ch/cri-containerd-release/cri-containerd-cni-1.4.3-linux-amd64.tar.gz" \
	--labels cvmfs_csi_enabled="true" \
	--labels cvmfs_csi_version="v1.0.0" \
	--labels etcd_tag="v3.4.13" \
	--labels eos_enabled="true" \
	--labels heapster_enabled="false" \
	--labels heat_container_agent_tag="train-stable-2" \
	--labels helm_client_tag="v2.16.6" \
	--labels ignition_version="3.3.0-experimental" \
	--labels influx_grafana_dashboard_enabled="false" \
	--labels ingress_controller="nginx" \
	--labels keystone_auth_enabled="true" \
	--labels kube_csi_enabled="true" \
	--labels kube_csi_version="cern-csi-1.0-2" \
	--labels kube_tag="v1.21.1-cern.0" \
	--labels kubeapi_options="--feature-gates=RemoveSelfLink=false,GenericEphemeralVolume=true" \
	--labels kubecontroller_options="--feature-gates=RemoveSelfLink=false" \
	--labels kubelet_options="--feature-gates=RemoveSelfLink=false --system-reserved=memory=500Mi" \
	--labels logging_http_destination="http://monit-logs.cern.ch:10012/" \
	--labels logging_include_internal="true" \
	--labels logging_producer="cmswebk8s" \
	--labels logging_type="http" \
	--labels manila_enabled="true" \
	--labels manila_version="v0.3.0" \
	--labels metrics_server_enabled="true" \
	--labels nvidia_gpu_enabled="false" \
	--labels nvidia_gpu_tag="31-5.4.8-200.fc31.x86_64-455.28" \
	--labels oidc_groups_claim="cern_roles" \
	--labels oidc_groups_prefix="cern_egroup:" \
	--labels oidc_enabled="false" \
	--labels oidc_issuer_url="ttps://auth.cern.ch/auth/realms/cern" \
	--labels oidc_username_claim="cern_upn" \
	--labels oidc_username_prefix="cern_uid:" \
	--labels tiller_enabled="true" \
	--labels tiller_tag="v2.16.6" \
	--labels use_podman="true" \
	--labels cinder_csi_enabled="true" \
	--coe kubernetes \
	--image 4d30ed6c-e899-4025-b604-b75862840351 \
	--external-network CERN_NETWORK \
	--fixed-network CERN_NETWORK \
	--network-driver calico \
	--dns-nameserver 137.138.16.5,137.138.17.5 \
	--flavor m2.2xlarge \
	--master-flavor m2.large \
	--docker-storage-driver overlay2 \
	--server-type vm

# list tempaltes
openstack --os-project-name "$namespace" coe cluster template list
