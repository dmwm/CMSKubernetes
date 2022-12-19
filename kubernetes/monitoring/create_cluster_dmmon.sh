#!/bin/bash
# Creates Kubernetes cluster using openstack templates for DM Monitoring(cms-dm-monit)
# Please
#   - find a latest kubernetes template and use it:
#     * 'openstack coe cluster template list'
#     * 'openstack coe cluster template show kubernetes-1.22.9-1 -f yaml'
#   - Define your master and node counts
#   - Define your master and node FLAVORS: 'openstack flavor list'
#   - Define EOS enabled or not, default is TRUE.
#   - Define ingress controller, default NGINX; it can be traefik too!
#

namespace=${OS_PROJECT_NAME:-"CMS Web"}
name=$1
template=${2:-"kubernetes-1.22.9-1"}

usage="create_cluster.sh <name> <template_name, if not provided will use $template>"
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    echo "$usage"
    exit 0
fi
echo "Creating cluster => NameSpace: ${namespace} , Name: ${name} , Template: ${template}"
echo "Check if EOS enabled! cms-dm-monit cluster does not need it."

sleep 10

openstack --os-project-name "$namespace" coe cluster create "$name" \
    --keypair cloud \
    --cluster-template "$template" \
    --master-count 1 \
    --master-flavor m2.large \
    --node-count 2 \
    --flavor m2.large \
    --merge-labels \
    --labels cinder_csi_enabled="true" \
    --labels logging_include_internal="true" \
    --labels logging_http_destination="http://monit-logs.cern.ch:10012/" \
    --labels logging_installer=helm \
    --labels eos_enabled="false" \
    --labels monitoring_enabled="true" \
    --labels logging_producer="cmswebk8s" \
    --labels ingress_controller="nginx" \
    --labels cern_enabled="true" \
    --labels keystone_auth_enabled="true" \
    --labels logging_type="http"

# Ref: https://cms-http-group.docs.cern.ch/k8s_cluster/cmsweb-deployment/
#
# READ the DOC: https://cmsmonit-docs.web.cern.ch/k8s/cluster_upgrades/#dm-mon
