#! /bin/sh

# Rucio server, daemons, and daemons for analysis

helm install --name cms-rucio-testbed --values cms-rucio-common.yaml,cms-rucio-server.yaml,cms-rucio-server-testbed.yaml,cms-rucio-testbed-db.yaml rucio/rucio-server
helm install --name cms-ruciod-testbed --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,cms-rucio-daemons-testbed.yaml,cms-rucio-testbed-db.yaml rucio/rucio-daemons
helm install --name cms-analysisd-testbed --values cms-rucio-common.yaml,cms-rucio-analysis-daemons.yaml,cms-rucio-daemons-testbed.yaml,cms-rucio-testbed-db.yaml rucio/rucio-daemons

# Graphite and other services
helm install --name graphite --values rucio-graphite.yaml,rucio-graphite-ingress.yaml,rucio-graphite-ingress-testbed.yaml,rucio-graphite-pvc.yaml kiwigrid/graphite

# Filebeat and logstash
helm install --name logstash --values cms-rucio-logstash.yml,logstash-filter-testbed.yml stable/logstash
helm install --name filebeat --values cms-rucio-filebeat.yml  stable/filebeat

