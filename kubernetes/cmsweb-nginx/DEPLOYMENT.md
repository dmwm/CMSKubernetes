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

### Cluster creation
The k8s cluster can be either created viw
[web UI](https://openstack.cern.ch/project/clusters) or manually by
login to lxplus-cloud and using an appropriate cmsweb template, e.g.
```
# ssh lxplus-cloud
# and use appropriate project name, here we use "CMS Webtools Mig"
openstack --os-project-name "CMS Webtools Mig" coe cluster template list
openstack --os-project-name "CMS Webtools Mig" coe cluster create --keypair cloud --cluster-template cmsweb-template-2xlarge cmsweb
```
Once cluster is created, you may check this with the following
command:
```
openstack --os-project-name "CMS Webtools Mig" coe cluster list
```
and verify that your cluster in `CREATE_COMPLETE` state, you need
to setup appropriate k8s environment to operate with your cluster.
If you just created a cluster you can setup your environment
as following:
```
# this step will create config file in your current directory
cd workdir
$(openstack --os-project-name "CMS Webtools Mig" coe cluster config cmsweb)
```
or if you already have a cluster then you may setup your environment as
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

To proceed get latest [CMSKubernetes](https://github.com/dmwm/CMSKubernetes) codebase
```
git clone git@github.com:dmwm/CMSKubernetes.git
```
and, prepare your cmsweb certificates and configuration areas.
The former should contain host and robot certificates for the cluster,
and later auth/secret files for every cmsweb service.

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
./deploy.sh create /path/cmsweb/config /path/certificates hmac

# OR, we should deploy two clusters
# deploy frontend cluster (assuming config.cmsweb k8s config)
export KUBECONFIG=/k8s/path/config.cmsweb
./deploy.sh frontend /path/cmsweb/config /path/certificates hmac

# deploy services cluster (assuming config.cmsweb-services k8s config)
export KUBECONFIG=/k8s/path/config.cmsweb-services
./deploy.sh services /path/cmsweb/config /path/certificates hmac
```

You may check status of your cluster with
```
./deploy.sh check
```

To re-generate all secrets use this command
```
./deploy.sh secrets /path/cmsweb/config /path/certificates hmac
```

To clean-up all services/secrets you run
```
./deploy.sh cleanup
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
  reqmgr2/reqmon/workqueue and couch (this option is presented in their yaml
  files)
- nginx ingress controller must access tls.key and tls.crt files while it is
  deployed, these files reside in ing secrets file. These files should have
  certificate matching k8s hostname
- robot certificates should be generated by CERN representative via
  ca.cern.ch They will be used to generate proxy and used by cervices to
  pass requests to the cluster
