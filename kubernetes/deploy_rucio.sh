#!/usr/bin/env bash


kubectl create secret generic dburl --from-file=DBURL.txt

kubectl replace --force -f rucio_server_cms.yaml


kubectl -n kube-system delete configmap traefik-conf
kubectl -n kube-system create configmap traefik-conf --from-file=rucio-traefik.toml

kubectl delete daemonset ingress-traefik -n kube-system
kubectl delete service ingress-traefik -n kube-system
kubectl delete -f rucio-ingress.yaml

kubectl apply -f rucio-traefik.yaml
kubectl apply -f rucio-ingress.yaml


