#! /bin/sh

set -x

# Remove landb loadbalance from all minions

echo "Removing DNS aliases from ALL minions in preparation for cluster decommissioning"

kubectl get node -o name | grep -E "minion|-node-" | while read node; do
  openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
done
