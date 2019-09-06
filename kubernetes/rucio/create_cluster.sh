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
