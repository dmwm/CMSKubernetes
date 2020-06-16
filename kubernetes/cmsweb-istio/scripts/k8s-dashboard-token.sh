#!/bin/bash
kubectl get secret -n kube-system | grep kubernetes-dashboard-token | awk '{print "kubectl describe secret "$1" -n kube-system"}' | /bin/sh | grep "token:" | awk '{print $2}'
