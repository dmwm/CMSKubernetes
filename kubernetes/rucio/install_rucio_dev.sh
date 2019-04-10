#! /bin/sh

# Ingress server

helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --set rbac.create=true --values nginx-ingress.yaml

# Rucio server, daemons, and daemons for analysis

helm install --name cms-rucio-testbed --values cms-rucio-common.yaml,cms-rucio-server-traefik.yaml,cms-rucio-server-dev.yaml,cms-rucio-dev-db.yaml rucio/rucio-server
helm install --name cms-ruciod-testbed --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-daemons-dev.yaml,cms-rucio-dev-db.yaml rucio/rucio-daemons

# Graphite and other services
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-ingress.yaml,rucio-graphite-ingress-dev.yaml,rucio-graphite-pvc.yaml kiwigrid/graphite

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,logstash-filter-dev.yml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

