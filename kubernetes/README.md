### Introduction
This repository contains specific kubernetes (k8s) configuration
files for various CMS clusters/applications.
- cmsmon: simple monitoring server
- cmsweb-traefik: cmsweb cluster deployment based on traefik middleware
- cmsweb-nginx: cmsweb cluster deployment based on nginx middleware
- k8s-whoami: simple deploy for whoami service
- rucio: deployment files for Rucio cluster
- tfass: deployment files for TFaaS service

### Kubernetes terminology
All definitions here are taken from [kubernetes](https://kubernetes.io/docs/concepts/) guide.
- Master: is a collection of three processes that run on a single node in your
  cluster, which is designated as the master node. Those processes are:
  kube-apiserver, kube-controller-manager and kube-scheduler.
- Node: a working machine (VM or physical node) that run your applications and
  cloud workflows. The Kubernetes master controls each node; you’ll rarely
  interact with nodes directly.
- Pod: is a group of one or more containers, with shared storage/network, and a
  specification for how to run the containers.
  A Pod is the basic building block of Kubernetes–the smallest and simplest
  unit in the Kubernetes object model that you create or deploy. A Pod
  represents a running process on your cluster.

  A Pod encapsulates an application container (or, in some cases, multiple
  containers), storage resources, a unique network IP, and options that govern
  how the container(s) should run. A Pod represents a unit of deployment: a
  single instance of an application in Kubernetes, which might consist of either
  a single container or a small number of containers that are tightly coupled and
  that share resources.

  Docker is the most common container runtime used in a Kubernetes Pod, but Pods
  support other container runtimes as well.

  Pods in a Kubernetes cluster can be used in two main ways:

  Pods that run a single container. The “one-container-per-Pod” model is the most
  common Kubernetes use case; in this case, you can think of a Pod as a wrapper
  around a single container, and Kubernetes manages the Pods rather than the
  containers directly.  Pods that run multiple containers that need to work
  together. A Pod might encapsulate an application composed of multiple
  co-located containers that are tightly coupled and need to share resources.
  These co-located containers might form a single cohesive unit of service–one
  container serving files from a shared volume to the public, while a separate
  “sidecar” container refreshes or updates those files. The Pod wraps these
  containers and storage resources together as a single manageable entity.

- Service: an abstractions which defines logical set of pods and a policy by
  which to access them - sometimes called a micro-service.

- Deployment controller provides declarative updates for Pods and ReplicaSets.

  You describe a desired state in a Deployment object, and the Deployment
  controller changes the actual state to the desired state at a controlled
  rate. You can define Deployments to create new ReplicaSets, or to remove
  existing Deployments and adopt all their resources with new Deployments.

- Ingress: collection of rules that allow inbound traffic reach cluster services.

- Traefik: is a proxy and load balancer in front of k8s cluster to route
  incomong user requests, for more information see
  [traefik documentation](https://docs.traefik.io/basics/).
  Traefik architecture consists of several sub-systems:
  - incoming requests end on entrypoints, as the name suggests, they are the
    network entry points into Traefik (listening port, SSL, traffic
    redirection...).
  - traffic is then forwarded to a matching frontend. A frontend defines routes
    from entrypoints to backends. Routes are created using requests fields
    (Host, Path, Headers...) and can match or not a request.
  - the frontend will then send the request to a backend. A backend can be
    composed by one or more servers, and by a load-balancing strategy.
  - Finally, the server will forward the request to the corresponding
    microservice in the private network.
  They can be explicitly defined in traefik configuration or parts of them
  can be delegated to the k8s, e.g. ingress controller.

### Network configuration
The network configuration on k8s cluster is quite complex and consists of
multiple layers. Probably, it is better to describe it via concrete example:
- first the incoming request arrives to traefik entry point, e.g. http port 80,
  then it can be routed to secure port 443 (https):
```
request -> traefik:entry_point:80 -> traefik:entry_point:443
```
- after that request can be either routed via traefik frontend routes to
  backends servers which will route it to corresponding app services within
  k8s cluster network or traefik can communicate with k8s ingress controller
  which will take care of this. We'll describe the later:
```
traefik:entry_point:443 -> ingress controller
  # here ingress controller uses routing rules to propagate
  # incoming request to destination path, e.g. /path
  # which is served by backend server with
  # serviceName: app  # app is a name of our microservice
  # servicePort: 1234 # is an internal port of our microservice 
  -> request to app internal port
```
We also use hostNetwork option in all cmsweb specific pods since we rely
on explicit ports and redirect rules among our services.

##### Kubernetes ports
- Port: Port is the port number which makes a service visible to other services
  running within the same k8s cluster.  In other words, in case a service wants
  to invoke another service running within the same Kubernetes cluster, it will
  be able to do so using port specified against "port" in the service spec file.
- Target Port: Target port is the port on the POD where the service is running.
  It is a port used by the application/microservice itself when it runs.
- Nodeport: Node port is the port on which the service can be accessed from
  external users using Kube-Proxy.

### Auto-scaling
It is possible to perform auto-scaling of the cluster to add extra
nodes. This can be done using the following command:
```
openstack coe cluster update <cluster_name> --os-project-name <Project Namespace> replace node_count=4
```

It won’t start new pods on the new nodes except for DaemonSets and so forth.
But newly started pods after an upgrade or crojobs or whatever will start to
use the new resources. You can also shrink it this way in which case killed
pods will be redistributed.

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

### Administration of kubernetes
We can perform some administration commands on master node of kubernetes
cluster. For example, clean-up or look-up docker images. To do that we need
to know our kube hostname
```
cluster=cmsweb # replace accordingly to your settings
host=`openstack --os-project-name "CMS Webtools Mig" coe cluster show $cluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
```
and then we can issue some command against our kubehost, e.g.
```
# look-up docker images on master node
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@${kubehost} "sudo docker images"
# clean-up docker images on master node
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@${kubehost} "sudo docker system prune -f -a"
```

### References
- [Kubernetes concepts](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [Kubernetes tutorials](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubernetes references](https://kubernetes.io/docs/reference/)
- [Kubernetest autoacaling](https://www.tutorialspoint.com/kubernetes/kubernetes_autoscaling.htm)
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
- [Kubernetes blogs](https://vitalflux.com/category/kubernetes/)
- [Kubernetes networking](http://alesnosek.com/blog/2017/02/14/accessing-kubernetes-pods-from-outside-of-the-cluster/)
- [Kubernetes networking guide](https://sookocheff.com/post/kubernetes/understanding-kubernetes-networking-model/)
- [Kubernetes DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Kubernetes cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes troubleshouting](https://learnk8s.io/troubleshooting-deployments)
