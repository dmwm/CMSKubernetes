#! /bin/sh

REPO=~/rucio-helm-charts # or rucio

SERVER_NAME=cms-rucio-dev
DAEMON_NAME=cms-ruciod-dev

# Ingress server

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --values nginx-ingress.yaml

# Rucio server, daemons, and daemons for analysis

helm install --name $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server-nginx.yaml,dev-rucio-server.yaml,dev-db.yaml,dev-release.yaml $REPO/rucio-server
helm install --name $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,dev-rucio-daemons.yaml,dev-db.yaml,dev-release.yaml $REPO/rucio-daemons

# Graphite and other services
kubectl create -f cms-rucio-storage.yaml
kubectl create -f rucio-graphite-pvc.yaml
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-nginx.yaml,dev-graphite.yaml kiwigrid/graphite

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,dev-logstash-filter.yaml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

kubectl delete job --ignore-not-found=true fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts

# Label is key to prevent it from also syncing datasets
kubectl delete configmap dataset-config
kubectl create configmap dataset-config --from-file=site-sync.yaml
kubectl apply -f dev-sync-jobs.yaml -l syncs=rses

# Set up landb loadbalance
numberIngressNodes=3
offset=2
n=0
kubectl get node -o name | grep minion | while read node; do
  [[ $((n++)) == $numberIngressNodes ]] && break
  kubectl label node ${node##node/} role=ingress
  # Remove any existing aliases
  openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
  ndns=$(($n + $offset))
  cnames="cms-rucio-graphite-dev--load-${ndns}-,cms-rucio-dev--load-${ndns}-,cms-rucio-auth-dev--load-${ndns}-"
  openstack server set --os-project-name CMSRucio --property landb-alias=$cnames ${node##node/}
done
