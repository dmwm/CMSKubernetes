## Kubernetes for CMS data-service
This document describes procedure how to setup kubernetes (k8s) cluster 
with CMS data-services using docker images. Here is a list of items
we need:
- an account on CMS build (docker) node, e.g. cmsdev15
- an account on openstack.cern.ch
- an account on docker.com to upload your docker image
- a docker image(s) we want to deploy to k8s
- a kubernetes cluster where we'll deploy our image

We'll assume that you can get an account on CMS build node as well as on
openstack.cern.ch

### Prerequisite
In order to access openstack nodes we need to create and upload rsa ssh key.
You may create and upload your rsa key as following:
```
# create new key, here we give a key name as: cloud
ssh-keygen -t rsa -f cloud

# upload you key to openstack with name cloud
openstack keypair create --public-key ~/.ssh/cloud.pub cloud
```

##### Robot certificates
For cmsweb operations we need to have a valid proxy on our backends.
Originally, we used operator proxy and uploaded it to myproxy server. The
cmsweb ProxySeed and ProxyRenew scripts were used.

Now, we can obtain CERN service account and apply for a Robot certificate.
Once received and we obtain robotcert.pem/robotkey.pem files and we need to
register them in [LCG VOMS server](https://lcg-voms2.cern.ch:8443).  Then,
we'll mount them in secrets volume in k8s cluster and use for acquiring proxies
within k8s pods, see
[proxy.sh](https://github.com/dmwm/CMSKubernetes/blob/master/docker/frontend/proxy.sh)
frontend file for example.

### Setup kubernetes cluster
You can create your kubernetes cluster either by login to openstack.cern.ch and
navigating to *Container infra* -> *Cluster Templates* and click on *CREATE
CLUSTER* or you can login to lxplus-cloud.cern.ch (or lxplus7-cloud-testing)
and create it via command line. We'll provide instruction here how to do the
later. First, login to lxplus-cloud.cern.ch or lxplus7-cloud-testing.cern.ch.
Then find out appropriate template

```
openstack coe cluster list
openstack coe cluster template show kubernetes
# here you need to create your ssh keypair (named cloud here)
# and upload it to openstack.cern.ch
openstack coe cluster create vkcluster --keypair cloud --cluster-template kubernetes-preview

# at later time the cluster can be deleted as following
openstack coe cluster delete vkcluster

# to deal with different project-name namespace we need to use the following commands
# here "CMS Webtools Mig" is our project-name namespace
# cmswebk8s is a name of a cluster we create and delete
openstack --os-project-name "CMS Webtools Mig" coe cluster list
# example of create command
openstack --os-project-name "CMS Webtools Mig" coe cluster create cmswebk8s --keypair cloud --cluster-template kubernetes-preview --flavor m2.2xlarge --node-count 2
# another example to allow every node in a cluster to have
# host certificates and krb5
openstack --os-project-name "CMS Webtools Mig" coe cluster create k8s --keypair cloud --cluster-template kubernetes-preview --flavor m2.2xlarge --labels cern_enabled=True
openstack --os-project-name "CMS Webtools Mig" coe cluster delete cmswebk8s
```

Here, we first list existing clusters, then existing template kubernetes and finally created
a custom cluster named `vkcluster` (change to your name). Please note, that you *must*
name your cluster with lower-case letters and no special symbols. Then, we can verify
that our cluster is up and running by using the following command:

```
openstack coe cluster show vkcluster
```

and in order to access it and plays with kubernetes commands we should setup the environment

```
cd your_dir
$(openstack coe cluster config vkcluster)
```

This will create few files: `ca.pem`, `cert.pem`, `key.pem` and `config`. At this time
the environment will be set and we can start using `kubectl` command. But if you'll login
next time you'll need to setup your environment by simply doing
```
export KUBECONFIG=/path/config
```
where `/path` is your area where you created aforementioned files.

### Setting up kubernetes pods/services
Please refer to [2] for kubernetes tutorial which describe the terminology.
Here we're going to use `kubectl` command to create pod and our service.
Let's start with inspecing existing node(s):
```
kubectl get node
NAME                              STATUS    AGE
vkcluster-dzegay3ktjak-minion-0   Ready     1d
```
Now, we can create and deploy our docker image as following (please substitute USERNAME and port number
accoringly):
```
# create new app from docker image to be accessible on given port
kubectl run kubernetes-das2go --image=USERNAME/das2go --port=8212
kubectl get pods
kubectl get deployments

export POD_NAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
kubectl logs $POD_NAME

# connect to my pod
kubectl exec -ti $POD_NAME bash
# now I should have a bash shell prompt on my pod
exit # exit from the shell/pod

# if we want to delete our deployment we'll do
kubectl delete deployment kubernetes-das2go
```

We already listed command how you can login into your pod and inspect your app
within it. It's time to expose it to be visible outside of internal cluster.

```
# expose our services to outside world
kubectl expose deployment/kubernetes-das2go --type="NodePort" --port 8212
service "kubernetes-das2go" exposed

kubectl get services
NAME                CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes          10.254.0.1       <none>        443/TCP          3d
kubernetes-das2go   10.254.138.221   <nodes>       8212:30695/TCP   7s

# check our service information
kubectl describe services/kubernetes-das2go
Name:                   kubernetes-das2go
Namespace:              default
Labels:                 run=kubernetes-das2go
Selector:               run=kubernetes-das2go
Type:                   NodePort
IP:                     10.254.138.221
Port:                   <unset> 8443/TCP
NodePort:               <unset> 30695/TCP
Endpoints:              10.100.39.6:8212
Session Affinity:       None
No events.

# if we want to delete our service we'll do
kubectl delete services -l run=kubernetes-das2go
```

Above we shown that our service is up and running and has open port `30695`.
This port and IP addresses above will change in your setup. In order to
access our app we need to know an external IP and PORT numbers. Here how
we can find them:

```
# get external port number from service template
export NODE_PORT=$(kubectl get services/kubernetes-das2go -o go-template='{{(index .spec.ports 0).nodePort}}')
# or inspect service information

# obtain public service IP which is visible at CERN network
openstack coe cluster show vkcluster | grep node_addresses

# now I can access my service as
host=`openstack coe cluster show vkcluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
curl http://$host:$NODE_PORT/das/
```

We are done.

### References

1. http://clouddocs.web.cern.ch/clouddocs/containers/quickstart.html
2. https://kubernetes.io/docs/tutorials/kubernetes-basics/
3. https://kubernetes.io/docs/reference/kubectl/docker-cli-to-kubectl/
4. http://blog.kubernetes.io/2015/10/some-things-you-didnt-know-about-kubectl_28.html
