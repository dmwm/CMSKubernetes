#! /bin/sh

helm del --purge ingress-nginx; 
helm del --purge cms-rucio-${INSTANCE}; 
helm del --purge cms-ruciod-${INSTANCE};
helm del --purge cms-webui-${INSTANCE};

helm del --purge logstash; 
helm del --purge filebeat; 

helm del --purge statsd-exporter;

n=0
kubectl get node -l role=ingress -o name | grep -v master | while read node; do
  # Remove any existing aliases
  openstack server unset --os-project-name CMSRucio --property landb-alias ${node##node/}
done

