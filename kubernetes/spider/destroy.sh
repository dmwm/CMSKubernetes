#!/bin/bash

# Delete deployments
kubectl delete -f accounts/spider-accounts.yaml
kubectl delete -f deployments/spider-redis.yaml
kubectl delete -f deployments/spider-redis-cp.yaml
kubectl delete -f deployments/spider-flower.yaml
kubectl delete -f deployments/spider-worker.yaml
kubectl delete -f service/spider-redis.yaml
kubectl delete -f service/spider-redis-cp.yaml
kubectl delete -f service/spider-flower.yaml
kubectl delete -f cronjobs/spider-cron-affiliation.yaml
kubectl delete -f cronjobs/spider-cron-queues.yaml
kubectl delete -f service/ingress.yaml

# Delete secrets
kubectl delete secrets amq-username -n spider
kubectl delete secrets amq-password -n spider
kubectl delete secrets es-conf -n spider
kubectl delete secrets collectors -n spider

# Delete PVC storages
kubectl delete -f storages/shared_redis.yaml
kubectl delete -f storages/shared_spider.yaml
kubectl delete -f storages/storage_class.yaml
