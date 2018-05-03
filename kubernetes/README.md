### Kubernetes deployment procedure

Here we describe how to deploy our services into kubernetes cluster.
This can be done using kubernetes yaml/json files which describe
the deployment procedure.

We provide the following examples:
- DAS service backend [das2go](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/das2go.yaml)
- DBS service backend [dbs2go](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/dbs2go.yaml)
- Frontend services [ing](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/ing.yaml)
- Traefik daemon [traefik](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/traefik.yaml)
These files specify deployment rules for our apps/services.
With these files we can deploy our services as following:

#### Secret files
Secret files, like DB passwords, server certificates, can be easily
added to kubernetes setup. To simplify the process we wrote helper scripts
for our services. Below you can see full procedure:

```
# create service secret files
make_das_secret.sh /tmp/das-proxy server.key server.crt
make_dbs_secret.sh /tmp/das-proxy server.key server.crt dbfile
make_ing_secret.sh server.key server.crt

# deploy secret files
kubectl apply -f ./das-secrets.yaml --validate=false
kubectl apply -f ./dbs-secrets.yaml --validate=false
kubectl apply -f ./ing-secrets.yaml --validate=false

# create secret file for traefik daemon,
# we create it in different namespace (kube-system)
kubectl -n kube-system create secret generic traefik-cert --from-file=server.crt --from-file=server.key
```

#### Traefik daemon deployment
[Traefik](https://traefik.io/) is a modern HTTP reverse proxy and load balancer
made to deploy microservices with ease. It supports several backends (Docker,
Swarm mode, Kubernetes, Marathon, Consul, Etcd, Rancher, Amazon ECS, and a lot
more) to manage its configuration automatically and dynamically.

Traefik will serve all incoming requests and redirect them to our backend.
On openstack it should be deployed (check) in kube-system namesapce.
Below are instructions how to manually deploy it to the kubernetes.
```
# start daemon (this step is required once the daemon is already runnign
# see next step and when I want to change the traefik configuration)
kubectl apply -f traefik.yaml --validate=false

# check that daemon is running (or it will start the daemonset on new cluster)
kubectl get daemonset -n kube-system

# get cluster node name
kubectl get node

# apply label to the node
kubectl label node <cluster name> role=ingress

# check node(s) with our label
kubectl get node -l role=ingress

# check that ingress traefik is running
kubectl -n kube-system get pod | grep traefik

# if necessary we can delete the traefik daemon
kubectl delete daemonset ingress-traefik -n kube-system

# create configmap for traefik
kubectl -n kube-system create configmap traefik-conf --from-file=traefik.toml

# and later we can create it again with our custom traefik manifest file
kubectl apply -f traefik.yaml --validate=false
kubectl -n kube-system get pod | grep traefik
kubectl logs ingress-traefik-btf4d -n kube-system
```

Please refer to [traefik.yaml]() manifiest file
and [traefik.toml]() configuration file for more details.
Also, please use the following posts for further details:
- [Traefik configuration](https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948)
- [Traefik files](https://github.com/patrickeasters/traefik-k8s-tls-example)
- [Traefik Kubernetes](https://docs.traefik.io/configuration/backends/kubernetes/)
- [Ingress+Traefik+LetsEncrypt](https://blog.osones.com/en/kubernetes-ingress-controller-with-traefik-and-lets-encrypt.html)

#### Backend services
Now it's time to deploy our backend services
```
# deploy our services
kubectl apply -f das2go.yaml
kubectl apply -f dbs2go.yaml

# on CERN AFS you will need to use the following commands:
kubectl apply -f das2go.yaml --validate=false
kubectl apply -f dbs2go.yaml --validate=false

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

#### Frontend deployment

The final piece is to put *smart router* (entry point) for our cluster
which will route requests to different backends. For that purpose we'll
use kubernetes Ingress resource. Its manifest file can be found
[here](https://github.com/vkuznet/CMSKubernetes/blob/master/kubernetes/ing.yaml).
It provides basic rules how to route requests to our application.

First, we need to obtain a domain name for our cluster. In provided manifest
file it is `MYHOST.XXX.COM` which you need to replace with your actual name.
The rest is trivial, we route DAS traffic to `/das` path and DBS traffic to
`/dbs` endpoint. 

Second, we need to start ingress daemon on our cluster and label our node
to have its ingress role. After that we need to deploy inress resource
with redirect rules.

Here is full procedure for our frontend:
```
# verify that our cluster has ingress controller enabled
openstack coe cluster show vkcluster | grep labels
# it should yield these label (among others): 'ingress_controller': 'traefik'

# obtain cluster name
host=`openstack coe cluster show vkcluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`

# start daemon
kubectl get daemonset -n kube-system

# apply label to the node, the 
kubectl label node <cluster name> role=ingress
# or via obtained kubehost variables
kubectl label node $kubehost role=ingress

# check node(s) with our label
kubectl get node -l role=ingress
# it should print something like this
NAME                              STATUS    AGE
myclusrer-lsdjflksdjfl-minion-0   Ready     23h

# check that ingress traefik is running
kubectl -n kube-system get pod | grep traefik
# it should print something like this:
ingress-traefik-lkjsdl                   1/1       Running   0          1h

# if necessary we can delete it in order for it be restarted
kubectl delete pod ingress-traefik-lkjsdl -n kube-system

# deploy ingress resource
kubectl apply -f ing.yaml

# verify that it runs and check its redirect rules:
kubectl get ing
NAME       HOSTS                ADDRESS   PORTS     AGE
frontend   MYHOST.web.cern.ch             80, 443   49m

kubectl describe ing frontend
Name:                   frontend
Namespace:              default
Address:
Default backend:        default-http-backend:80 (<none>)
TLS:
  ing-secret terminates
Rules:
  Host                          Path    Backends
  ----                          ----    --------
  MYHOST.web.cern.ch
                                /das            das2go:8212 (<none>)
                                /dbs            dbs2go:8989 (<none>)
                                /httpgo         httpgo:8888 (<none>)
Annotations:
  rewrite-target:       /
No events.
```

### Access Kubernetes dashboard

```
# get cluster token
token=`kubectl -n kube-system get secret | grep kubernetes-dashboard-token | awk '{print $1}'`
# this command will print your token
kubectl -n kube-system describe secret $token | grep token | awk '{print $2}'

# run proxy on port 8888
kubect proxy -p 8888

# create SSH tunnel to our proxy host (change lxhost.domain.name with your host name)
ssh -S none -L 8888:localhost:8888 valya@lxhost.domain.name

# open browser
http://localhost:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

# and choose Token authentication where enter your token from above
```

### References
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [Kubernetes tutorials](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubernetes references](https://kubernetes.io/docs/reference/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Kubernetes NodePort vs LoadBalancer vs Ingress](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0)
- [Kubernetes deployment](https://pascalnaber.wordpress.com/2017/10/27/configure-ingress-on-kubernetes-using-azure-container-service/)
- [Traefik configuration](https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948)
- [Traefik files](https://github.com/patrickeasters/traefik-k8s-tls-example)
- [Traefik Kubernetes](https://docs.traefik.io/configuration/backends/kubernetes/)
- [Ingress+Traefik+LetsEncrypt](https://blog.osones.com/en/kubernetes-ingress-controller-with-traefik-and-lets-encrypt.html)
- [Manage LetsEncrypt](https://github.com/vkuznet/kube-cert-manager)
- [Auto LetsEncrypt](https://github.com/jetstack/kube-lego)
- [Kubernetes Prometheus and Grafana](https://grafana.com/dashboards/315)
- [Kubernetes monitoring with Prometheus](https://itnext.io/kubernetes-monitoring-with-prometheus-in-15-minutes-8e54d1de2e13)
- [Prometheus setup for Kubernetes](https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/)

