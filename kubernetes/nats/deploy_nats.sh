#!/bin/bash

echo "Label minion nodes with ingress label"
kubectl get nodes | grep minion | awk '{print "kubectl label node "$1" role=ingress --overwrite"}' | /bin/sh

echo "Add ingress controller"
kubectl get nodes
node=`kubectl get nodes | grep minion | head -1 | awk '{print $1}'`

cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ing-nats
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: ${node}.cern.ch
    http:
      paths:
      - path: /nats
        backend:
          serviceName: nats-cluster
          servicePort: 4222
EOF

echo "Deploy NATS"
kubectl apply -f https://github.com/nats-io/nats-operator/releases/latest/download/00-prereqs.yaml
kubectl apply -f https://github.com/nats-io/nats-operator/releases/latest/download/10-deployment.yaml
kubectl get crd

echo "Let's watch when nats crd's are created, invoke CTRL+C when you see them"
watch -d kubectl get crd | grep nats

cat <<EOF | kubectl create -f -
apiVersion: nats.io/v1alpha2
kind: NatsCluster
metadata:
  name: nats-cluster
spec:
  size: 2
  version: "1.3.0"
EOF

echo "Now let's see if nats-cluster are Running..., press CTRL+C when you see them"
watch -d kubectl get nats --all-namespaces

echo "Let's test NATS server"
kubectl get ing | grep ing-nats | awk '{print "curl http://"$2"/nats"}' | /bin/sh
