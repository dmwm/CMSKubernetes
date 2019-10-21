### End-to-end setup for k8s
This document provides basic setup of k8s and demonstrate whole process of
cluster creation and service deployment.
```
# let's create a new cluster, the command to create a cluster is the following
# openstack coe cluster create test-cluster --keypair cloud --cluster-template kubernetes-1.13.10-1
# but we'll use it with specific flags:
# cern_tag and cern_enabled forces creation of host certificates
# ingress_controller defines which ingress controller we'll use
# tiller_enabled defines tiller service to allow to deploy k8s Helmpackages
#
# here is an example how to create a cluster
# openstack coe cluster create test-cluster --keypair <name> --cluster-template <tmpl_name> <labels>
# for example
# openstack coe cluster create test-cluster --keypair cloud --cluster-template kubernetes-1.13.10-1 --labels cern_tag=qa --labels ingress_controller="nginx" --labels tiller_enabled=true --labels cern_enabled="true"

# But the above template may not contain ALL labels we may want
# to use at the end, to solve this problem we'll create a cluster
# with standard template

# To start, let's create your working area
mkdir wdir
cd wdir

# you should probably clone CMSKubernetes repository
git clone git@github.com:dmwm/CMSKubernetes.git

# for this excercise we'll use httpgo application/service
# therefore we'll copy httpgo.yaml file in our working area
cp CMSKubernetes/kubernetes/k8s-whoami/httpgo.yaml .
cp CMSKubernetes/kubernetes/cmsweb-nginx/scripts/create_templates.sh .

# first we'll create a new template with all labels suitable for cms
# by default create_template use "CMS Web" project, therefore
# we'll use "default" project by resetting OS_PROJECT_NAME
# the create_template.sh script will create cmsweb-temaplate-medium

OS_PROJECT_NAME="" ./create_templates.sh
openstack coe cluster template list
+--------------------------------------+------------------------+
| uuid                                 | name                   |
+--------------------------------------+------------------------+
| 5b2ee3b5-2f85-4917-be7c-11a2c82031ad | kubernetes-preview     |
| 49187d11-6442-43da-bedc-695ae522e8c5 | swarm-preview          |
| 17760a5f-8957-4794-ab96-0d6bd8627282 | swarm-18.06-1          |
| ab08b219-3246-4995-bf76-a3123f69cb4f | swarm-1.13.1-2         |
| a6d5b08d-f90a-46b4-900c-a5bd170664a5 | cmsweb-template-medium |
| 0b6d5c5f-976a-4f05-9edb-06489bc6538b | kubernetes-1.14.6-1    |
| 6b4fc2c2-00b0-410d-a784-82b6ebdd85bc | kubernetes-1.13.10-1   |
| 30c8db8a-49d0-470d-b9c6-dd684d4d0079 | kubernetes-1.15.3-2    |
+--------------------------------------+------------------------+

# now, let's create a cluster with cmsweb-template
openstack coe cluster create test-cluster --keypair cloud --cluster-template cmsweb-template-medium
```

You may check its status like this (please note that IDs or names will be assigned dynamically
and you output will have different ones):
```
openstack coe cluster list
+--------------------------------------+--------------+---------+------------+--------------+--------------------+---------------+
| uuid                                 | name         | keypair | node_count | master_count | status             | health_status |
+--------------------------------------+--------------+---------+------------+--------------+--------------------+---------------+
| 62ca8a05-c209-4f2e-b684-f6cf90d90b06 | test-cluster | cloud   |          1 |            1 | CREATE_IN_PROGRESS | None          |
+--------------------------------------+--------------+---------+------------+--------------+--------------------+---------------+
```
Once cluster is created you'll have the following status
```
openstack coe cluster list
+--------------------------------------+--------------+---------+------------+--------------+-----------------+---------------+
| uuid                                 | name         | keypair | node_count | master_count | status          | health_status |
+--------------------------------------+--------------+---------+------------+--------------+-----------------+---------------+
| 62ca8a05-c209-4f2e-b684-f6cf90d90b06 | test-cluster | cloud   |          1 |            1 | CREATE_COMPLETE | None          |
+--------------------------------------+--------------+---------+------------+--------------+-----------------+---------------+

# at this step we just need to create our configuration, it can be done as following
$(openstack coe cluster config test-cluster)
```
Now it is time to deploy our first service. For that we'll use
[httpgo](https://github.com/dmwm/CMSKubernetes/tree/master/docker/httpgo) application/service.
It represents basic HTTP server written in Go language. Its docker image
is available at [cmssw/httpgo](https://cloud.docker.com/u/cmssw/repository/docker/cmssw/httpgo)
repository. The associated k8s deployment file can be found
[here](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/k8s-whoami/httpgo.yaml).
```
# inspect available nodes on a cluster
kubectl get nodes
NAME                                 STATUS   ROLES    AGE     VERSION
test-cluster-l3kt5awszhwr-master-0   Ready    master   18m     v1.13.10
test-cluster-l3kt5awszhwr-minion-0   Ready    <none>   7m57s   v1.13.10

# at this point you can check which pods are available
kubectl get pods --all-namespaces

# label our minion node with ingress label to start nginx daemon
kubectl label node test-cluster-l3kt5awszhwr-minion-0 role=ingress --overwrite

# check that label is applied to the node
kubectl get node -l role=ingress

# deploy k8s application/service
kubectl create -f httpgo.yaml --validate=false
# or
kubectl apply -f httpgo.yaml --validate=false

# in a few minutes you'll be able to see your pods
kubectl get pods

# if your pod is still in creation mode, e.g.
kubectl get pods
NAME                                 READY   STATUS              RESTARTS   AGE
httpgo-deployment-6f9978c7f5-tw2lp   0/1     ContainerCreating   0          4m
# you may check what it is doing using this command:
kubectl describe pods/httpgo-deployment-6f9978c7f5-tw2lp

# we can check which services do we have
kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
httpgo       ClusterIP   10.254.190.161   <none>        8888/TCP   28s
kubernetes   ClusterIP   10.254.0.1       <none>        443/TCP    21m
```

In order to access our service we have few options:
- use NodePort
- use hostNetwork and hostPort
- use ingress controller
You may read about these options [here](https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0) and [here](http://alesnosek.com/blog/2017/02/14/accessing-kubernetes-pods-from-outside-of-the-cluster/).

**Excercise:** feel free to change httpgo.yaml and change service to
```
kind: Service
apiVersion: v1
metadata:
  name: httpgo
spec:
  type: NodePort
  ports:
  - port: 8888 # the port here is matching port used in veknet/httpgo cotainer
    protocol: TCP
    name: http
    nodePort: 31000
  selector:
    app: httpgo
```
With such change you'll be able to access your httpgo application on port
31000 of the cluster.

Meanwhile, we'll deploy ingress controller
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: "test-cluster-l3kt5awszhwr-minion-0.cern.ch"
    http:
      paths:
      - path: /http
        backend:
          serviceName: httpgo
          servicePort: 8888
```
(save this file as ing.yaml) and deploy it as following:
```
# deploy ingress controller
kubectl apply -f ing.yaml --validate=false
# check ingress controller
kubectl get ing
# find details about ingress controller
kubectl describe ing
```


And now we can access our service
```
curl http://test-cluster-l3kt5awszhwr-minion-0.cern.ch/http

GET /http HTTP/1.1
Header field "X-Real-Ip", Value ["137.138.33.220"]
Header field "X-Forwarded-For", Value ["137.138.33.220"]
Header field "X-Forwarded-Host", Value ["test-cluster-l3kt5awszhwr-minion-0.cern.ch"]
Header field "X-Forwarded-Proto", Value ["http"]
Header field "X-Scheme", Value ["http"]
Header field "User-Agent", Value ["curl/7.29.0"]
Header field "Accept", Value ["*/*"]
Header field "X-Request-Id", Value ["6cfced8477e71024a1489570ddedcc5d"]
Header field "X-Forwarded-Port", Value ["80"]
Header field "X-Original-Uri", Value ["/http"]
Host = "test-cluster-l3kt5awszhwr-minion-0.cern.ch"
RemoteAddr= "10.100.1.1:32938"


Finding value of "Accept" ["*/*"]
Hello Go world!!!
```
