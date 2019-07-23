#! /bin/sh


export REPO=~/rucio-helm-charts # or rucio

export SERVER_NAME=cms-rucio-${INSTANCE}
DAEMON_NAME=cms-ruciod-${INSTANCE}
UI_NAME=cms-webui-${INSTANCE}

# Ingress server. With correct labels we should not need this anymore.

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --values nginx-ingress.yaml

# Rucio server, daemons, and daemons for analysis

helm install --name $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server.yaml,${INSTANCE}-rucio-server.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-server
helm install --name $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${INSTANCE}-rucio-daemons.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-daemons
helm install --name $UI_NAME --values cms-rucio-common.yaml,cms-rucio-webui.yaml,${INSTANCE}-rucio-webui.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-ui

# statsd exporter to prometheus
helm install --name statsd-exporter  --values ${INSTANCE}-statsd-exporter.yaml ~/CMSKubernetes/helm/rucio-statsd-exporter

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,${INSTANCE}-logstash-filter.yaml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

kubectl delete job --ignore-not-found=true fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts

# Label is key to prevent it from also syncing datasets
kubectl apply -f dataset-configmap.yaml
kubectl apply -f ${INSTANCE}-sync-jobs.yaml -l syncs=rses

# Set up landb loadbalance
numberIngressNodes=3
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
  cnames="cms-rucio-stats-${INSTANCE}--load-${n}-,cms-rucio-${INSTANCE}--load-${n}-,cms-rucio-auth-${INSTANCE}--load-${n}-,cms-rucio-webui-${INSTANCE}--load-${n}-"
  openstack server set --os-project-name CMSRucio --property landb-alias=$cnames ${node##node/}
done
