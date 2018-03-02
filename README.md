## Kubernetes for CMS data-service
This document describe procedure how to setup kubernetes data-service
using custom image of CMS data-service. We need few pieces to start with:
- an account on CMS build (docker) node, e.g. cmsdev15
- an account on openstack.cern.ch
- an account on docker.com to upload your docker image
- a docker image we want to deploy
- a kubernetes cluster where we'll deploy our image

We'll assume that you can get an account on CMS build node as well as on
openstack.cern.ch

### How to build docker image for CMS data-service
In order to build docker image please login to CMS build (docker) node and
navigate to your favorite directory. The docker commands immitate unix ones
and here just few examples you will need to know:
```
### build image
docker build -t das2go .

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image
docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t das2go /bin/bash

### remove existing image
docker rmi das2go

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### references
https://stackoverflow.com/questions/18497688/run-a-docker-image-as-a-container#18498313
https://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers#17237701
http://goinbigdata.com/docker-run-vs-cmd-vs-entrypoint/
```

So, the first step is to create a Docker file. Here is an example for
[das2go](github.com/vkuznet/CMSKubernetes/Dockerimage) package.

Now with this file we can build our docker image as simple as following:
```
docker build -t USERNAME/das2go .
```
Here, USERNAME should point to your docker username account. This command will build a docker image
in USERNAME namespace. Once build we should see it with output from this command:
```
docker images
```
To access/run the image we can run the following command:
```
docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t USERNAME/das2go /bin/bash
```
If it is visible and you can access it it's time to upload it to docker hub:
```
docker push USERNAME/das2go:tagname
```
Here `:tagname` is optional originally, but you may substitute it with any given tag, e.g.
`:v1`. Then login to docker.com and verify that you can see your image.


### Setup kubernetes cluster
You can create your kubernetes cluster either by login to openstack.cern.ch and
navigating to *Container infra* -> *Cluster Templates* and click on *CREATE CLUSTER*
or you can login to lxplus-cloud.cern.ch and create it via command line. We'll provide
instruction here how to do the later. First, login to lxplus-cloud.cern.ch. Then
find out appropriate template

```
openstack coe cluster list
openstack coe cluster template show kubernetes
# here you need to create your ssh keypair (named lxplus here)
# and upload it to openstack.cern.ch
openstack coe cluster create --name vkcluster --keypair lxplus --cluster-template kubernetes
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
