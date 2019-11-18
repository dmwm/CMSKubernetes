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

  **Please note** this can only be done once you create a cluster
  and register your minions in LanDB
  (see this
  [section](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/docs/cmsweb-deployment.md#registration-of-k8s-nodes-on-landb)),
  but you need it before deploying
  cmsweb services and frontends on k8s cluster
```
# when you obtain p12 certificate you need to convert it to pem files
openssl pkcs12 -in Certificates.p12 -clcerts -nokeys -out cmsweb-hostcert.pem
openssl pkcs12 -in Certificates.p12 -nocerts -nodes -out cmsweb-hostkey.pem
```
- obtain robot certificates from [ca.cern.ch](https://ca.cern.ch)
  to be used by services to obtain grid proxy
- you must have your own configuration area with service configs. So far we
provide a common config area in this
[repository](https://gitlab.cern.ch/cmsweb-k8s/preprod)

#### cmsweb k8s deploy script
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
  cluster    create openstack cluster
  services   deploy services cluster
  frontend   deploy frontend cluster
  ingress    deploy ingress controller
  monitoring deploy monitoring components
  crons      deploy crons components
  secrets    create secrets files


Envrionments:
  CMSWEB_CLUSTER   defines name of the cluster to be created (default cmsweb)
  OS_PROJECT_NAME  defines name of the OpenStack project (default "CMS Web")
  CMSWEB_HOSTNAME  defines cmsweb hostname (default cmsweb-test.cern.ch)
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
# CMSWEB_TMPL cluster template, default: cmsweb-template-stable
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

# PLEASE NOTE: if in your project space there is no cmsweb templates
# you may create them as following (the script will create
# cmsweb-template-stable which we will use below):
./scripts/create_templates.sh

# create a cmsweb cluster from specific template (cmsweb-template-stable)
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-stable cmsweb

# or using one template but specify different parameters
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-stable --node-count 2 cmsweb

# for cmsweb we'll create two clusters: cmsweb-frontend and cmsweb-services
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-stable --flavor m2.large --node-count 4 cmsweb-frontend
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-stable --flavor m2.2xlarge --node-count 4 cmsweb-services
```

Once cluster is created, you may check its status with the following command:
```
openstack coe cluster list
```
Please verify that your cluster is in `CREATE_COMPLETE` state, if so, then you
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
export KUBECONFIG=$PWD/config
```

**Please note:** for cmsweb we'll create two clusters, cmsweb-frontend and
cmsweb-services. Therefore when we'll create configuration files we'll
make a copy of config file:
```
# create cmsweb-frontend cluster
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-stable --flavor m2.xlarge --node-count 2 cmsweb-frontend
# create its configuration
$(openstack coe cluster config cmsweb-frontend)
cp config config.cmsweb-frontend
# when operating with cmsweb-frontend cluster please set
export KUBECONFIG=/path/config.cmsweb-frontend

# create cmsweb-services cluster
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-stable --flavor m2.2xlarge --node-count 2 cmsweb-services
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

### Cluster deployment

To proceed, get latest [CMSKubernetes](https://github.com/dmwm/CMSKubernetes) codebase
```
git clone git@github.com:dmwm/CMSKubernetes.git
```
and, prepare your cmsweb certificates and configuration areas.
The former should contain host and robot certificates for the cluster,
and the later should contain auth/secret/configuration files for every cmsweb service.

#### Configuration area
The configuration area can be downloaded from
```
git clone https://gitlab.cern.ch/cmsweb-k8s/preprod.git
mkdir /path/config
cp -r preprod/* /path/config

# the /path/config will contain a tree structure of all
# cmsweb services where individual directories will contain
# service configuration files. You need to update them accordingly
# with your secret files. Every file from service config area
# will appear in /data/srv/current/<service>/ area in your pod
```
and then adjusted accordingly to your project/deployment needs.


**Please note:** for frontend deployment we rely on
`cmsweb.services` file in configuration area which will contain
a hostname of service's cluster. For example, in `cmsweb-test.cern.ch`
setup we use two cluster, a frontend cluster with alias
`cmsweb-test.cern.ch` and backend cluster with alias `cmsweb-srv.cern.ch`.
The later one is defined in `frontend/cmsweb.services` configuration file.
You may need to change it accordingly to your cluster setup. This hostname
will be used by frontend configuration files in all redirect rules.

#### Certificates area
You should also obtain your service certificates and put them
into your `/path/certificates` path to be used by `deploy.sh` script.
The deployment script expects to read the following files (here
names should be as listed below):
```
# robot certificates will be used to obtain proxy file
robotkey.pem
robotcert.pem
# host certificate for your cluster should match URL of your cluster
cmsweb-hostkey.pem
cmsweb-hostcert.pem
```
These files can be obtained from [ca.cern.ch](https://ca.cern.ch/ca/).
The robot certificates can be issued only to person affiliated to CERN,
while host certificates can be obtained by anyone. You may replace
robot certificate with your personal grid certificate while doing
a testing.

#### cmsweb deployment procedure
Finally, you may deploy new k8s cluster as following:
```
# locate your kubernetes area
cd CMSKubernetes/kubernetes/cmsweb

# if necessary setup KUBECONFIG environment, e.g.
export KUBECONFIG=/path/config

# obtain hmac file
./scripts/gen_hmac.sh hmac

# NOTE: we can either deploy single cluster with hostNetwork: true
# option in ALL yaml files (you may need to change that)
# single cluster deployment:
export KUBECONFIG=/path/config
./scripts/deploy.sh create frontend /path/config /path/certificates hmac
```

For cmsweb deployment we'll use two clusters, see cmsweb
k8s cluster [architecture](architecture.md). One is called **frontend cluster**
which will host our cmsweb frontends and another is called **service cluster**
which will hold our cmsweb backend services.

#### frontend cluster deployment
```
# deploy frontend cluster
To proceed with creation of frontend cluster we need to pass `CMSWEB_HOSTNAME` variable to `deploy.sh` script which will
be used to replace frontend hostnames for ingress.
(load balancing k8s middleware to route client's requests):

export KUBECONFIG=/path/config.cmsweb-frontend
CMSWEB_HOSTNAME=<frontend hostname> ./scripts/deploy.sh create frontend /path/config /path/certificatesfrontend hmac
```

#### service cluster deployment
To proceed with creation of service cluster we need to pass two variables `CMSWEB_HOSTNAME` and `CMSWEB_HOSTNAME_FRONTEND` to `deploy.sh` script. `CMSWEB_HOSTNAME_FRONTEND` will be used to obtain frontend cluster IPs and `CMSWEB_HOSTNAME` will be used for replacement of service hostnames in ingress'es. 
(load balancing k8s middleware to route client's requests):
```
# deploy services cluster
export KUBECONFIG=/path/config.cmsweb-services
CMSWEB_HOSTNAME_FRONTEND=<frontend hostname> CMSWEB_HOSTNAME=<services hostname> ./scripts/deploy.sh create services /path/config /path/certificatesservices hmac
```

You may check the status of your cluster with the following command:
```
./scripts/deploy.sh status
```

#### Registration of k8s nodes on LanDB
At this point, if cluster is working, we may need to add frontend and services
minions to landb. This is required to have proper load balancers to both
clusters.  It can be done as following:
```
# if required set proper OS_PROJECT_NAME environment
export OS_PROJECT_NAME="CMS Web"

# command syntax how to add new aliases to LanDB
openstack server set --property landb-alias=[YOUR_DOMAIN]--load-0- [YOUR_MINION-0]
openstack server set --property landb-alias=[YOUR_DOMAIN]--load-1- [YOUR_MINION-1]

# command syntax how to delete alias from LanDB
openstack server unset --property landb-alias <minion-name>
```
Please note that `--load-0-` and `--load-1-` (and so on) parameters are
counters which can start with any number and incremented along with minions
IDs.

For example, to make cmsweb-test.cern.ch point to our frontend
minions we'll perform these actions:
```
openstack server set --property landb-alias=cmsweb-test--load-0- <cmsweb-frontend-minion-0>
openstack server set --property landb-alias=cmsweb-test--load-1- <cmsweb-frontend-minion-1>
```
add, to add similar aliases for cmsweb-srv minions we'll do:
```
openstack server set --property landb-alias=cmsweb-srv--load-0- <cmsweb-services-minion-0>
openstack server set --property landb-alias=cmsweb-srv--load-1- <cmsweb-services-minion-1>
```
Finally, when we ready, we can make `cmsweb-test` domain visible from outside of CERN network
by placing [request a firewall exception](https://cern.service-now.com/service-portal/service-element.do?name=Firewall-Service).
**Please note:** DO NOT expose `cmsweb-srv` domain to outside world. We only
open `cmsweb-test` domain since it performs full authentication.

### Additional tune-ups
After our cluster is created we may need to perform additional tune-ups
such as nginx controller adjustements, granding user access rights
or adding additional (persistent) storage to our services. This section
describes all of these steps.

#### Adjusting ngix controller settings
The default nginx controller has limited resources and needs an adjustement.
The procedure can be done using the following script:
```
./scripts/adjust_ing.sh
# it will run series of commands and create ing-values.yaml file
# you may need to edit this file and change two parts:
# - adjust controller resources to
   resources:
     limits:
       cpu: 1000m
       memory: 256Mi
     requests:
       cpu: 1000m
       memory: 256Mi
# but do not adjust defaultBackend resources

# and change tcp port to add this part (only necessary for frontend cluster)
tcp:
  "8443": default/frontend:8443

# once changes are applied you need to upload this file back to k8s
# this can be done as following
export HELM_HOME="$HOME/ws/helm_home"
export HELM_TLS_ENABLE="true"
export TILLER_NAMESPACE="magnum-tiller"
helm upgrade nginx-ingress stable/nginx-ingress  --namespace=kube-system -f ing-values.yaml --recreate-pods
```
This step is required until CERN IT k8s team will fix the nginx controller,
see this [ticket](https://its.cern.ch/jira/browse/OS-9959) for resources
and this [ticket](https://its.cern.ch/jira/browse/OS-9960) for port settings.

#### Granting user access rights to namespaces
Once cluster is created we may need to grant certain users an access edit
rights to their service namespace, e.g. DBS developer should be able to
edit DBS namespace/services/pods. This can be done as following
```
./scripts/add_user.sh <user> <namespace>
```

#### Adding additional (persistent) storage for data-service needs
To perform this action you need to modify data-service
yaml manifest file and create additional storage. Please refer
to [storage](storage.md) documentation.

### Cluster maintenance
When cluster is deployed we may perform various actions. For example,
to re-generate all secrets we'll use this command
```
./scripts/deploy.sh create secrets /path/config /path/certificates hmac
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
kubectl apply -f <srv>.yaml --validate=false
```
The delete step is optional since it will be done automatically for you if
your service configuration (yaml file) is differ from existing (deployed) one.

Please note, you may need to create a new docker image for your service
data-service if you want to change the release, and/or add some functionality.
The docker image is listed in service yaml file and you may apply
particular tag to choose appropriate image.

The `scripts/deploy.sh` script provides additional actions, such as `scale`,
`status monitoring`, etc. But so far they are considered experimental.

### Additional notes
- once you created an entire cluster you may remove `hmac` file, but if you
  plan to upgrade your cluster you may wish to keep it around
  - you can always re-generate `hmac` file, but then you need to re-deploy
  all services with it in `cmsweb-frontend` and `cmsweb-services` clusters
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

