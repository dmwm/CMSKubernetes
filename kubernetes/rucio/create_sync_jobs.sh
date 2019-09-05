#! /bin/bash

kubectl apply -f int-dataset-configmap.yaml 

kubectl apply -f dev-sync-jobs.yaml -l syncs=datasets
kubectl apply -f int-sync-jobs.yaml -l syncs=datasets

helm install --name statsd-exporter  --values sync-statsd-exporter.yaml cms-kubernetes/rucio-statsd-exporter

kubectl create job --from=cronjob/dev-sync-datasets dev-sync2
kubectl create job --from=cronjob/int-sync-datasets int-sync2


