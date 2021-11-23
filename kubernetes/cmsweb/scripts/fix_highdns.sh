#!/bin/bash

kubectl rollout restart deployment coredns -n kube-system
kubectl rollout restart ds k8s-keystone-auth -n kube-system
