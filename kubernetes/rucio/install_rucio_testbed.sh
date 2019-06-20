#! /bin/sh

REPO=~/rucio-helm-charts # or rucio

SERVER_NAME=cms-rucio-testbed
DAEMON_NAME=cms-ruciod-testbed
UI_NAME=cms-webui-testbed

# Ingress server

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --values nginx-ingress.yaml

# Rucio server, daemons, and daemons for analysis

helm install --name $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server.yaml,testbed-rucio-server.yaml,testbed-db.yaml,testbed-release.yaml $REPO/rucio-server
helm install --name $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,testbed-rucio-daemons.yaml,testbed-db.yaml,testbed-release.yaml $REPO/rucio-daemons
helm install --name $UI_NAME --values cms-rucio-common.yaml,cms-rucio-webui.yaml,testbed-rucio-webui.yaml,testbed-db.yaml,testbed-release.yaml $REPO/rucio-ui

# Graphite and other services
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-nginx.yaml,rucio-graphite-pvc.yaml,testbed-graphite.yaml kiwigrid/graphite

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,testbed-logstash-filter.yaml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

kubectl delete job --ignore-not-found=true fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts

# Label is key to prevent it from also syncing datasets
kubectl apply -f testbed-sync-jobs.yaml -l syncs=rses

# Set up landb loadbalance
numberIngressNodes=3
n=0
kubectl get node -o name | while read node; do
  [[ $((n++)) == $numberIngressNodes ]] && break
  kubectl label node ${node##node/} role=ingress
  cnames="cms-rucio-graphite-testbed--load-${n}-,cms-rucio-testbed--load-${n}-,cms-rucio-auth-testbed--load-${n}-,cms-rucio-webui-testbed--load-${ndns}-"
  openstack server set --os-project-name CMSRucio --property landb-alias=$cnames ${node##node/}
  # teardown:
  # openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
done
