#! /bin/sh

REPO=~/rucio-helm-charts # or rucio

SERVER_NAME=cms-rucio-testbed
DAEMON_NAME=cms-ruciod-testbed

# Ingress server

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --set rbac.create=true --values nginx-ingress.yaml

# Rucio server, daemons, and daemons for analysis

helm install --name $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server-nginx.yaml,nginxtest-rucio-server.yaml,cms-rucio-dev-db.yaml $REPO/rucio-server
helm install --name $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-daemons-oldtest.yaml,cms-rucio-dev-db.yaml $REPO/rucio-daemons

# Graphite and other services
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-nginx.yaml,rucio-graphite-pvc.yaml kiwigrid/graphite

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,logstash-filter-oldtest.yml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

kubectl delete job fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts
