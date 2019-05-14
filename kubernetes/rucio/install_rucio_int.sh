#! /bin/sh
PREFIX=int
SERVER_NAME=cms-rucio-$PREFIX
DAEMON_NAME=cms-ruciod-$PREFIX

# Ingress server

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --set rbac.create=true --values nginx-ingress.yaml

# Rucio server and daemons

helm install --name $SERVER_NAME --values cms-rucio-common.yaml,cms-rucio-server.yaml,${PREFIX}-rucio-server.yaml,${PREFIX}-db.yaml ~/rucio-helm-charts/rucio-server
helm install --name $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${PREFIX}-rucio-daemons.yaml,${PREFIX}-db.yaml ~/rucio-helm-charts/rucio-daemons

# Graphite and other services
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-nginx.yaml,int-graphite.yaml,rucio-graphite-pvc.yaml kiwigrid/graphite

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,${PREFIX}-logstash-filter.yml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

kubectl delete job --ignore-not-found=true fts
kubectl create job --from=cronjob/${DAEMON_NAME}-renew-fts-proxy fts


