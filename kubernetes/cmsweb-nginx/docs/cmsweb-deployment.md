### Introduction
Thsi document provides step-by-step instructions how to deploy
cmsweb cluster to kubernetes. For specific details about k8s
please refer to this [document](README.md)

### Requirements
In order to proceed with cluster creation you need to decide and obtain the
following items:

- decide on hostname to be used for k8s cluster, e.g.
  https://cmsweb-test.web.cern.ch
- obtain hostkey/hostcert.pem files for this hostname, the DN of certificate
  file should match DN of the host, e.g.
  Subject: DC=ch, DC=cern, OU=computers, CN=cmsweb-test.web.cern.ch
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
# OS_PROJECT_NAME controls project name (namespace of the cluster)
# CMSWEB_CLUSTER cluster name
# CMSWEB_TMPL cluster template
# CMSWEB_KEY your key pair name

./scripts/deploy.sh create cluster
```
or follow these manual steps
```
# ssh lxplus-cloud
# set appropriate projet name
export OS_PROJECT_NAME="CMS Web"
# and use appropriate project name, here we use "CMS Webtools Mig"
openstack coe cluster template list
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-2xlarge cmsweb
# or using one template but specify different parameters
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-large --flavor m2.xlarge --node-count 2 cmsweb-frontend
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-large --flavor m2.2xlarge --node-count 2 cmsweb-services
```

Once cluster is created, you may check its status this with the following
command:
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
```
or, if you already have a cluster, you may setup your environment as
```
cd workdir
export KUBECONFIG=$PWD/config
```

Please inspect your minion node before moving forward. We found that quite
often nodes fail to provide valid host certificate files. To do that please
login to one of your minion nodes:
```
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o
StrictHostKeyChecking=no fedora@<minion-node-name>
# and inspect /etc/grid-security area
ls -l /etc/grid-security
```
It should contain proper content, i.e. hostcert.pem and hostkey.pem files.

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
cd CMSKubernetes/kubernetes

# if necessary setup KUBECONFIG environment, e.g.
export KUBECONFIG=/k8s/path/config

# obtain hmac file
gen_hmac.sh hmac

# NOTE: we can either deploy single cluster with hostNetwork: true
# option in ALL yaml files (you may need to change that)
# single cluster deployment:
export KUBECONFIG=/k8s/path/config
./scripts/deploy.sh create frontend /path/cmsweb/config /path/certificates hmac

# OR, we should deploy two clusters
# deploy frontend cluster (assuming config.cmsweb k8s config)
export KUBECONFIG=/k8s/path/config.cmsweb
./scripts/deploy.sh create frontend /path/cmsweb/config /path/certificates hmac

# deploy services cluster (assuming config.cmsweb-services k8s config)
export KUBECONFIG=/k8s/path/config.cmsweb-services
./scripts/deploy.sh create services /path/cmsweb/config /path/certificates hmac
```

You may check the status of your cluster with the following command:
```
./scripts/deploy.sh status
```

At this point, if cluster is working, we may need to adjust landb
settings to have load balancer for out frontend minions. This can be done as
following:
```
export OS_PROJECT_NAME="CMS Web"
# add new aliases, please replace minion names here
openstack server set --property landb-alias=[YOUR_DOMAIN]--load-1- [YOUR_MINION-0]
openstack server set --property landb-alias=[YOUR_DOMAIN]--load-2- [YOUR_MINION-1]
# for example, to make cmsweb-test.cern.ch point to our frontend
# minions we'll perform this actions. Please note that --load-0- and --load-1-
# parameters are counters which can start with any number and incremented
# along with minions
openstack server set --property landb-alias=cmsweb-test--load-0- cmsweb-frontend-minion-0
openstack server set --property landb-alias=cmsweb-test--load-1- cmsweb-frontend-minion-1
```

And, to make `cmsweb-test` visible from outside of CERN network we'll need to
[request a firewall exception](https://cern.service-now.com/service-portal/service-element.do?name=Firewall-Service)

To re-generate all secrets use this command
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

##### List of specific actions we need to do on k8s
- hostkey/hostcert.pem files with hostname matching k8s host should reside in
  frontend configureation area
- for reqmgr2 we need to use pycurl that's why its install script perform the
  patch of the code to use it, otherwise default httplib2 library fails to
  pass requests from reqmgr2 to couchdb
- we need to use hostNetwork to allow communication between
  reqmgr2/reqmon/workqueue and couch if we will operate with a single
  cluster, otherwise it is irrelevant
- nginx ingress controller must access tls.key and tls.crt files while it is
  deployed, these files reside in ingress secrets file. These files should have
  certificate matching k8s hostname
- robot certificates should be generated by CERN representative via
  ca.cern.ch They will be used to generate proxy and used by cervices to
  pass requests to the cluster
