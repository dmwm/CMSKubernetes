# Set up landb loadbalance
export INSTANCE=int

numberIngressNodes=3
n=0
kubectl get node -o name | grep minion | while read node; do
  [[ $((n++)) == $numberIngressNodes ]] && break
  kubectl label --overwrite node ${node##node/} role=ingress
done

n=0
kubectl get node -l role=ingress -o name | grep -v master | while read node; do
  # Remove any existing aliases
  openstack server unset --property landb-alias ${node##node/}
  echo $((n++))
  cnames="cmsrucio-stats-${INSTANCE}--load-${n}-,cmsrucio-${INSTANCE}--load-${n}-,cmsrucio-auth-${INSTANCE}--load-${n}-,cmsrucio-webui-${INSTANCE}--load-${n}-,cmsrucio-eagle-${INSTANCE}--load-${n}-,cmsrucio-trace-${INSTANCE}--load-${n}-"
  openstack server set --property landb-alias=$cnames ${node##node/}
done


