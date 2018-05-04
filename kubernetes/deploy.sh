#!/bin/bash

echo "### secrets"
kubectl delete secret/das-secrets
kubectl delete secret/dbs-secrets
kubectl delete secret/ing-secrets
kubectl delete secret/frontend-secrets
kubectl delete secret/httpsgo-secrets
kubectl -n kube-system delete secret/traefik-cert
kubectl -n kube-system delete configmap traefik-conf

sleep 2

voms-proxy-init -voms cms -rfc
voms_file="/tmp/x509up_u`id -u`"
dbsconfig=dbsconfig.json
dasconfig=dasconfig.json
httpsgoconfig=httpsgoconfig.json
user_crt=/afs/cern.ch/user/v/valya/.globus/usercert.pem
server_key=/afs/cern.ch/user/v/valya/private/certificates/server.key
server_crt=/afs/cern.ch/user/v/valya/private/certificates/server.crt
server_host_key=/afs/cern.ch/user/v/valya/private/certificates/vkcluster-hostkey.pem
server_host_crt=/afs/cern.ch/user/v/valya/private/certificates/vkcluster-hostcert.pem
dbfile=/afs/cern.ch/user/v/valya/private/dbfile
./make_das_secret.sh $voms_file $server_key $server_crt $dasconfig
./make_dbs_secret.sh $voms_file $server_key $server_crt $dbsconfig $dbfile
./make_ing_secret.sh $server_key $server_crt
./make_frontend_secret.sh $voms_file
./make_httpsgo_secret.sh $httpsgoconfig
kubectl apply -f das-secrets.yaml --validate=false
kubectl apply -f dbs-secrets.yaml --validate=false
kubectl apply -f ing-secrets.yaml --validate=false
kubectl apply -f frontend-secrets.yaml --validate=false
kubectl apply -f httpsgo-secrets.yaml --validate=false
kubectl -n kube-system create secret generic traefik-cert \
    --from-file=$user_crt \
    --from-file=$server_crt \
    --from-file=$server_key \
    --from-file=$server_self_crt \
    --from-file=$server_self_key \
    --from-file=/afs/cern.ch/user/v/valya/private/certificates/CERN-CA.crt \
    --from-file=/afs/cern.ch/user/v/valya/private/certificates/CERN-CA1.crt \
    --from-file=/afs/cern.ch/user/v/valya/private/certificates/CERN-Root-CA2.crt

kubectl -n kube-system create configmap traefik-conf --from-file=traefik.toml

sleep 2

kubectl get secrets
kubectl -n kube-system get secrets
kubectl -n kube-system get configmap

echo
echo "### label node"
clsname=`kubectl get nodes | tail -1 | awk '{print $1}'`
kubectl label node $clsname role=ingress --overwrite
kubectl get node -l role=ingress

echo
echo "### ingress"
kubectl delete daemonset ingress-traefik -n kube-system
sleep 2
kubectl -n kube-system apply -f traefik.yaml --validate=false

echo
echo "### app services"
kubectl delete -f das2go.yaml
kubectl delete -f dbs2go.yaml
kubectl delete -f httpgo.yaml
kubectl delete -f httpsgo.yaml
kubectl delete -f frontend.yaml
kubectl delete -f ing.yaml

sleep 2

kubectl apply -f das2go.yaml --validate=false
kubectl apply -f dbs2go.yaml --validate=false
kubectl apply -f httpgo.yaml --validate=false
kubectl apply -f httpsgo.yaml --validate=false
kubectl apply -f frontend.yaml --validate=false
kubectl apply -f ing.yaml --validate=false

#echo "deploy prometheus"
#sleep 2

#kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-service.yaml
#kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-deployment.yaml
#kubectl -n monitoring delete -f kubernetes-prometheus/config-map.yaml

#kubectl create namespace monitoring
#kubectl -n monitoring apply -f kubernetes-prometheus/config-map.yaml --validate=false
#kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-deployment.yaml --validate=false
#kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-service.yaml --validate=false
#kubectl -n monitoring get deployments
#kubectl -n monitoring get pods
#prom=`kubectl -n monitoring get pods | grep prom | awk '{print $1}'`
#echo "### we may access prometheus as following"
#echo "kubectl -n monitoring port-forward $prom 9090:9090"

#kubectl -n monitoring delete -f Grafana-Prometheus-weave/prometheus-service.yaml
#kubectl -n monitoring delete -f Grafana-Prometheus-weave/prometheus-deployment.yaml
#kubectl -n monitoring delete -f Grafana-Prometheus-weave/prometheus-config.yaml

#kubectl -n monitoring apply -f Grafana-Prometheus-weave/prometheus-config.yaml
#kubectl -n monitoring apply -f Grafana-Prometheus-weave/prometheus-deployment.yaml --validate=false
#kubectl -n monitoring apply -f Grafana-Prometheus-weave/prometheus-service.yaml --validate=false

#kubectl -n monitoring get deployments
#kubectl -n monitoring get pods
#kubectl -n monitoring get svc
#prom=`kubectl -n monitoring get pods | grep prom | awk '{print $1}'`
#echo "### we may access prometheus as following"
#echo "kubectl -n monitoring port-forward $prom 9090:9090"
