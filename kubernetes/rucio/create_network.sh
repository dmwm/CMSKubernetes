#! /bin/sh

# Set up landb loadbalance
numberIngressNodes=3
n=0
kubectl get node -o name | grep node | grep -v master | while read node; do
  [[ $((n++)) == $numberIngressNodes ]] && break
  kubectl label --overwrite node ${node##node/} role=ingress
done

# Change this value by two or three if setting up a cluster like int2/dev2 etc to avoid collision in the LANDB names
n=0
kubectl get node -l role=ingress -o name | grep -v master | while read node; do
  # Remove any existing aliases
  openstack server unset --property landb-alias ${node##node/}
  echo $((n++))
  cnames="cms-rucio-stats--load-${n}-,cms-rucio--load-${n}-,cms-rucio-auth--load-${n}-,cms-rucio-webui--load-${n}-,cms-rucio-eagle--load-${n}-,cms-rucio-trace--load-${n}-"
  openstack server set --property landb-alias=$cnames ${node##node/}
done



