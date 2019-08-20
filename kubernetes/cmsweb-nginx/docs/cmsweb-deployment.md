### Introduction
Thsi document provides step-by-step instructions how to deploy
cmsweb cluster to kubernetes. For specific details about k8s
please refer to this [document](README.md)

### Requirements
In order to proceed with cluster creation you need to decide and obtain the
following items:

- decide on hostname to be used for k8s cluster, e.g.
  https://cmsweb-test.cern.ch
- obtain hostkey/hostcert.pem files for this hostname, the DN of certificate
  file should match DN of the host, e.g.
  Subject: DC=ch, DC=cern, OU=computers, CN=cmsweb-test.cern.ch
  See [ca.cern.ch](https://ca.cern.ch/ca/host/Request.aspx?template=CERNHostCertificate2YearsCustomSubject)
- obtain robot certificates from [ca.cern.ch](https://ca.cern.ch)
  to be used by services to obtain grid proxy

##### cmsweb k8s deploy script
We provide special deploy script to perform most of the deployment tasks.
Here its structure
```
./scripts/deploy.sh
Usage: deploy.sh ACTION DEPLOYMENT CONFIGURATION_AREA CERTIFICATES_AREA HMAC

Script actions:
  help       show this help
  cleanup    cleanup services
  create     create cluster with provided deployment
  scale      scale given deployment services
  status     check status of the services

Deployments:
  cluster    create openstack clsuter
  services   deploy services cluster
  frontend   deploy frontend cluster
  ingress    deploy ingress controller
  monitoring deploy monitoring components
  crons      deploy crons components
  secrets    create secrets files
```

### Cluster creation
The k8s cluster can be either created via
[web UI](https://openstack.cern.ch/project/clusters) or manually by
login to lxplus-cloud cluster and using an appropriate cmsweb template.
You may use the following command for cluster creation
```
# you may setup the following environment variables:

# OS_PROJECT_NAME controls project name/namespace, default: "CMS Web"
# CMSWEB_CLUSTER cluster name, default: cmsweb
# CMSWEB_TMPL cluster template, default: cmsweb-template-2xlarge
# CMSWEB_KEY your key pair name, default: cloud

# for example, create cmsweb-frontend cluster
CMSWEB_CLUSTER=cmsweb-frontend ./scripts/deploy.sh create cluster
# and create cmsweb-services cluster
CMSWEB_CLUSTER=cmsweb-services ./scripts/deploy.sh create cluster
```
or follow these manual steps
```
# ssh lxplus-cloud

# set appropriate projet name
export OS_PROJECT_NAME="CMS Web"

# list existsing templates
openstack coe cluster template list

# create a cmsweb cluster from specific template (cmsweb-template-2xlarge)
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-2xlarge cmsweb

# or using one template but specify different parameters
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-2xlarge --node-count 2 cmsweb

# for cmsweb we'll create two clusters: cmsweb-frontend and cmsweb-services
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-large --flavor m2.xlarge --node-count 2 cmsweb-frontend
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-large --flavor m2.2xlarge --node-count 2 cmsweb-services
```

Once cluster is created, you may check its status this with the following command:
```
openstack coe cluster list
```
Please verify that your cluster is in `CREATE_COMPLETE` state, if so then you
need to setup an appropriate k8s environment to operate with your cluster.  If
you just created a cluster you can setup your environment as following:
```
# this step will create config file in your current directory
cd workdir
$(openstack coe cluster config cmsweb)
# the command above will create config file in your local directory
# and setup KUBECONFIG pointing to it
```
or, if you already have a cluster, you may setup your environment as
```
cd workdir
export KUBECONFIG=$PWD/config
```

Please note, for cmsweb we'll create two clusters, cmsweb-frontend and
cmsweb-services. Therefore when we'll create configuration files we'll
make a copy of config file:
```
# create cmsweb-frontend cluster
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-large --flavor m2.xlarge --node-count 2 cmsweb-frontend
# create its configuration
$(openstack coe cluster config cmsweb-frontend)
cp config config.cmsweb-frontend
# when operating with cmsweb-frontend cluster please set
export KUBECONFIG=/path/config.cmsweb-frontend

# create cmsweb-services cluster
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-large --flavor m2.2xlarge --node-count 2 cmsweb-services
# create its configuration
$(openstack coe cluster config cmsweb-services)
cp config config.cmsweb-services
# when operating with cmsweb-services cluster please set
export KUBECONFIG=/path/config.cmsweb-services
```

Please inspect your minion nodes before moving forward. We found that quite
often nodes fail to provide valid host certificate files. To do that please
login to one of your minion nodes:
```
# obtain minion nodes
kubectl get node

# login to your minion node
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@<minion-node-name>
# and inspect /etc/grid-security area
ls -l /etc/grid-security
```
It should contain proper content, i.e. hostcert.pem and hostkey.pem files.

Later, if you need to increase number of minions for your cluster and/or
remove some this can be done using the following command:
```
# replace node count to 3
openstack coe cluster update cmsweb-services replace node_count=3
```
Please see [cluster maintenance](http://clouddocs.web.cern.ch/clouddocs/containers/maintenance.html)
documention for more options.

##### Cluster deployment

To proceed, get latest [CMSKubernetes](https://github.com/dmwm/CMSKubernetes) codebase
```
git clone git@github.com:dmwm/CMSKubernetes.git
```
and, prepare your cmsweb certificates and configuration areas.
The former should contain host and robot certificates for the cluster,
and the later should contain auth/secret/configuration files for every cmsweb service.

Finally, you may deploy new k8s cluster as following:
```
# locate your kubernetes area
cd CMSKubernetes/kubernetes/cmsweb-nginx

# if necessary setup KUBECONFIG environment, e.g.
export KUBECONFIG=/k8s/path/config

# obtain hmac file
./scripts/gen_hmac.sh hmac

# NOTE: we can either deploy single cluster with hostNetwork: true
# option in ALL yaml files (you may need to change that)
# single cluster deployment:
export KUBECONFIG=/k8s/path/config.cmsweb-frontend
./scripts/deploy.sh create frontend /path/cmsweb/config /path/certificates hmac

# OR, we should deploy two clusters
# deploy frontend cluster (assuming config.cmsweb k8s config)
export KUBECONFIG=/k8s/path/config.cmsweb-frontend
./scripts/deploy.sh create frontend /path/cmsweb/config /path/certificates hmac

# deploy services cluster (assuming config.cmsweb-services k8s config)
export KUBECONFIG=/k8s/path/config.cmsweb-services
./scripts/deploy.sh create services /path/cmsweb/config /path/certificates hmac
```

You may check the status of your cluster with the following command:
```
./scripts/deploy.sh status
```

##### Registration of k8s nodes on LanDB
At this point, if cluster is working, we may need to add frontend and services
minions to landb. This is required to have proper load balancers to both
clusters.  It can be done as following:
```
# if required set proper OS_PROJECT_NAME environment
export OS_PROJECT_NAME="CMS Web"

# command syntax how to add new aliases to LanDB
openstack server set --property landb-alias=[YOUR_DOMAIN]--load-0- [YOUR_MINION-0]
openstack server set --property landb-alias=[YOUR_DOMAIN]--load-1- [YOUR_MINION-1]
```
Please note that `--load-0-` and `--load-1-` (and so on) parameters are
counters which can start with any number and incremented along with minions
IDs.

For example, to make cmsweb-test.cern.ch point to our frontend
minions we'll perform these actions:
```
openstack server set --property landb-alias=cmsweb-test--load-0- cmsweb-frontend-minion-0
openstack server set --property landb-alias=cmsweb-test--load-1- cmsweb-frontend-minion-1
```
add, to add similar aliases for cmsweb-srv minions we'll do:
```
openstack server set --property landb-alias=cmsweb-srv--load-0- cmsweb-services-minion-0
openstack server set --property landb-alias=cmsweb-srv--load-1- cmsweb-services-minion-1
```
Finally, when we ready, we can make `cmsweb-test` visible from outside of CERN network
by placing [request a firewall exception](https://cern.service-now.com/service-portal/service-element.do?name=Firewall-Service).

##### cluster maintenance
When cluster is deployed we may perform various actions. For example,
to re-generate all secrets we'll use this command
```
./scripts/deploy.sh create secrets /path/cmsweb/config /path/certificates hmac
```
To clean-up all services/secrets you can run this command:
```
./scripts/deploy.sh cleanup
```

The individual services can be redeployed within existing cluster at any time
by using the following command:
```
# delete existing service (optional)
kubectl delete -f <srv>.yaml
# apply/deploy new service
kubectl apply -f <srv>.yaml
```
The delete step is optional since it will be done automatically for you if
your service configuration (yaml file) is differ from existing (deployed) one.

Please note, you may need to create a new docker image for your service
data-service if you want to change the release, and/or add some functionality.
The docker image is listed in service yaml file and you may apply
particular tag to choose appropriate image.

##### Additional notes
- hostkey/hostcert.pem files with hostname matching k8s host should reside in
  frontend configureation area
- for reqmgr2 we need to use pycurl that's why its install script perform the
  patch of the code to use it, otherwise default httplib2 library fails to
  pass requests from reqmgr2 to couchdb
- for single clsuter (when frontend and cmsweb services resides all together
  within a single clsuter) we need to use hostNetwork to allow communication between
  reqmgr2/reqmon/workqueue and couch, otherwise it is irrelevant
- nginx ingress controller must access tls.key and tls.crt files while it is
  deployed, these files reside in ingress secrets file. These files should have
  certificate matching k8s hostname
- robot certificates should be generated by CERN representative via
  ca.cern.ch They will be used to generate proxy and used by cervices to
  pass requests to the cluster
