#! /bin/bash

# Create secrets for logstash

kubectl create secret generic  logstash-pipeline --from-file=pipeline-bleeding.conf --namespace kube-system
kubectl create secret generic  cern-bundle --from-file=/etc/pki/tls/certs/CERN-bundle.pem --namespace kube-system

# Start logstash and then the parts of filebeat

kubectl create -f logstash.yaml

kubectl create -f filebeat-config.yaml
kubectl create -f filebeat-clusterrole.yaml
kubectl create -f filebeat-ds.yaml
