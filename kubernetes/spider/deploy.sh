#!/bin/bash

# namespace
kubectl create namespace spider

# accounts
kubectl apply -f accounts/spider-accounts.yaml

# pvc storages
kubectl apply -f storages/cephfs-storage.yaml

# secrets, "$secrets" points to secrets repo
kubectl create secret generic amq-username -n spider --from-file=$secrets/cms-htcondor-es/amq-username
kubectl create secret generic amq-password -n spider --from-file=$secrets/cms-htcondor-es/amq-password
kubectl create secret generic es-conf -n spider --from-file=$secrets/cms-htcondor-es/es-conf
kubectl create secret generic collectors -n spider --from-file=$secrets/cms-htcondor-es/collectors

# ingress
kubectl apply -f service/ingress.yaml

# pods
kubectl apply -f deployments/spider-flower.yaml
kubectl apply -f deployments/spider-redis.yaml
kubectl apply -f deployments/spider-redis-cp.yaml
kubectl apply -f deployments/spider-worker.yaml

# services
kubectl apply -f service/spider-flower.yaml
kubectl apply -f service/spider-redis.yaml
kubectl apply -f service/spider-redis-cp.yaml

# crons
kubectl apply -f cronjobs/spider-cron-affiliation.yaml
kubectl apply -f cronjobs/spider-cron-queues.yaml
