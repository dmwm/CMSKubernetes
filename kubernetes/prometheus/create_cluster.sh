#!/bin/bash
set -e  # exit script if error occurs

keyname=$1
clustername=$2
tmpl=$3
USAGE="Usage: $ bash <this_script>.sh <mykeyname> <clustername> <cluster-template>"

if [ -z "$keyname" ]; then
    printf "The name of your OpenStack SSH key is required as a runtime parameter.\n";
    printf "$USAGE\n"
    exit
elif [ -z "$clustername" ]; then
    printf "Please enter a name for your new cluster.\n"
    printf "$USAGE\n"
    exit
elif [ -z "$tmpl" ]; then
    printf "Please enter a name for your cluster template.\n"
    printf "$USAGE\n"
    exit
fi

printf "Hi!\nUse CTRL+C to exit the 'watch' screen when all nodes reach 'RUNNING' state."

printf "\nCreating cluster..."
openstack coe cluster create $clustername --keypair $keyname --cluster-template $tmpl --node-count 2 --node-flavor=m2.2xlarge
watch -d openstack coe cluster list
printf "* Finished creating cluster.\n"

printf "Setting up cluster config and context..."
openstack coe cluster config $clustername --dir ~/.kube --force
printf "* Finished configuring your local kubectl with your new cluster '$clustername'."

printf "Once you created a cluster please do..."
kubectl get node | grep minion | \
    awk '{split($1,a,"minion-"); print "openstack server set --property landb-alias=cms-prometheus--load-"a[2]"- "$1""}'
