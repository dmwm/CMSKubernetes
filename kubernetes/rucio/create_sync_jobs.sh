#! /bin/bash

export INSTANCE=sync

# Set up landb loadbalance
numberIngressNodes=2
n=0
kubectl get node -o name | grep minion | while read node; do
  [[ $((n++)) == $numberIngressNodes ]] && break
  kubectl label --overwrite node ${node##node/} role=ingress
done

n=0
kubectl get node -l role=ingress -o name | grep -v master | while read node; do
  # Remove any existing aliases
  openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
  echo $((n++))
  cnames="cms-rucio-stats-${INSTANCE}--load-${n}-"
  openstack server set --os-project-name CMSRucio --property landb-alias=$cnames ${node##node/}
done

kubectl apply -f int-dataset-configmap.yaml 

kubectl apply -f dev-sync-jobs.yaml -l syncs=datasets
kubectl apply -f int-sync-jobs.yaml -l syncs=datasets

helm install --name statsd-exporter  --values sync-statsd-exporter.yaml cms-kubernetes/rucio-statsd-exporter

kubectl create job --from=cronjob/dev-sync-datasets dev-sync-`date +%s`
kubectl create job --from=cronjob/int-sync-datasets int-sync-`date +%s`

echo "Don't forget to create secrets for int and dev. Should have a dedicated one later since only fts-cert is needed"

