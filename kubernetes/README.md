### Kubernetes deployment procedure

Here we describe how to deploy our services into kubernetes cluster.
This can be done using kubernetes yaml/json files which describe
the deployment procedure.

We provide the following examples:
- DAS service backend [das2go](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/das2go.yaml)
- DBS service backend [dbs2go](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/dbs2go.yaml)
- Frontend services [ing](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/ing.yaml)
These files specify deployment rules for our apps/services.
With these files we can deploy our services as following:

```
# create service secret files
make_das_secret.sh /tmp/das-proxy server.key server.crt
make_dbs_secret.sh /tmp/das-proxy server.key server.crt dbfile
make_ing_secret.sh server.key server.crt

# deploy our services
kubectl apply -f ./das2go.yaml
kubectl apply -f ./dbs2go.yaml

# on CERN AFS you will need to use the following commands:
kubectl apply -f ./das2go.yaml --validate=false
kubectl apply -f ./dbs2go.yaml --validate=false

# check our apps are running
kubectl get pods
NAME                      READY     STATUS    RESTARTS   AGE
das2go-867d867bc5-gr48g   1/1       Running   0          56m
dbs2go-5cf464d4fd-2wzbp   1/1       Running   0          56m

# get more info
kubectl describe pod <pod_name>

# if apps are running we can inspect our services
kubectl get services
NAME         CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
das2go       10.254.6.121    <nodes>       8212:32259/TCP   57m
dbs2go       10.254.139.45   <nodes>       8989:30739/TCP   57m
kubernetes   10.254.0.1      <none>        443/TCP          2d
```
