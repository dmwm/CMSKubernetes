#! /bin/sh

REPO=~/rucio-helm-charts # or rucio

SERVER_NAME=cms-rucio-dev
DAEMON_NAME=cms-ruciod-dev
UI_NAME=cms-webui-dev

# Ingress server

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --values nginx-ingress.yaml

# Rucio server, daemons, and daemons for analysis

helm install --name $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server.yaml,dev-rucio-server.yaml,dev-db.yaml,dev-release.yaml $REPO/rucio-server
helm install --name $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,dev-rucio-daemons.yaml,dev-db.yaml,dev-release.yaml $REPO/rucio-daemons
helm install --name $UI_NAME --values cms-rucio-common.yaml,cms-rucio-webui.yaml,dev-rucio-webui.yaml,dev-db.yaml,dev-release.yaml $REPO/rucio-ui

# statsd exporter to prometheus
kubectl apply -f dev-statsd-exporter.yaml

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,dev-logstash-filter.yaml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

kubectl delete job --ignore-not-found=true fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts

# Label is key to prevent it from also syncing datasets
kubectl apply -f dataset-configmap.yaml
kubectl apply -f dev-sync-jobs.yaml -l syncs=rses

# Set up landb loadbalance
numberIngressNodes=3
n=0
kubectl get node -o name | grep minion | while read node; do
  [[ $((n++)) == $numberIngressNodes ]] && break
  kubectl label node ${node##node/} role=ingress
done

n=0
kubectl get node -l role=ingress -o name | grep -v master | while read node; do
  # Remove any existing aliases
  openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
  echo $((n++))
  cnames="cms-rucio-stats-dev--load-${n}-,cms-rucio-dev--load-${n}-,cms-rucio-auth-dev--load-${n}-,cms-rucio-webui-dev--load-${n}-"
  openstack server set --os-project-name CMSRucio --property landb-alias=$cnames ${node##node/}
done
