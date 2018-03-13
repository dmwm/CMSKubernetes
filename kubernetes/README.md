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

At this point we exposed two back-end services: `das2go` and `dbs2go`.
They both operatate in separate pods and exposed at different IP addresses
on our cluster.

The final piece is to put *smart router* (entry point) for our cluster
which will route requests to different backends. For that purpose we'll
use kubernetes Ingress. Its manifest file can be found
[here](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/ing.yaml).
It provides basic rules how to route requests to our application. First,
we need to obtain a domain name for our cluster. In provided manifest file
it is `MYHOST.XXX.COM` which you need to replace with your actual name.
The rest is trivial, we route DAS traffic to `/das` path and DBS traffic
to `/dbs` endpoint. To deploy our frontend we apply the following:
```
kubectl apply -f ./ing.yaml
```

### References
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [Kubernetes tutorials](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubernetes references](https://kubernetes.io/docs/reference/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Kubernetes NodePort vs LoadBalancer vs Ingress](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)
