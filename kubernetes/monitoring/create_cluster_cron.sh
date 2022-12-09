#!/bin/bash
# Creates Kubernetes cluster using openstack templates for CRON
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
echo "Check if EOS enabled! CRON cluster needs it."

sleep 10

openstack --os-project-name "$namespace" coe cluster create "$name" \
    --keypair cloud \
    --cluster-template "$template" \
    --master-count 1 \
    --master-flavor m2.large \
    --node-count 2 \
    --flavor m2.xlarge \
    --merge-labels \
    --labels cinder_csi_enabled="true" \
    --labels logging_include_internal="true" \
    --labels logging_http_destination="http://monit-logs.cern.ch:10012/" \
    --labels logging_installer=helm \
    --labels eos_enabled="true" \
    --labels monitoring_enabled="true" \
    --labels logging_producer="cmswebk8s" \
    --labels ingress_controller="nginx" \
    --labels cern_enabled="true" \
    --labels keystone_auth_enabled="true" \
    --labels logging_type="http"

# Ref: https://cms-http-group.docs.cern.ch/k8s_cluster/cmsweb-deployment/
#                -- Helpful commands --
# openstack flavor list
# openstack coe cluster delete "name of the cluster"
# openstack coe cluster template list
# openstack coe cluster list
# openstack coe cluster config "name of the cluster"
# openstack server set --property landb-alias=YOUR-CLUSTER-ALIAS--load-0- [MINION-0]
# openstack server set --property landb-alias=YOUR-CLUSTER-ALIAS--load-1- [MINION-1]
# openstack server set --property landb-alias=YOUR-CLUSTER-ALIAS--load-2- [MINION-2]
# Check /eos/cms is there
# k create -f https://gitlab.cern.ch/kubernetes/automation/charts/cern/raw/master/eosxd/examples/eos-client-example.yaml
