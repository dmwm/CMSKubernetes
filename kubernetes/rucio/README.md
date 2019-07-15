Adapted from rucio instructions here: https://github.com/rucio/helm-charts/tree/master/rucio-server

# Accessing the existing kubernetes clusters

The instructions below are for a fresh setup of a new kubernetes cluster. 
Most people will only need to access an existing cluster to view logs, change configs, etc. 
This is much simpler:

    ssh lxplus-cloud.cern.ch

    mkdir [directory to hold cluster files]
    cd [directory to hold cluster files]
    `openstack coe cluster config  --os-project-name CMSRucio [cluster name, eg. cmsruciodev1]`
    
even that is only needed the first time one accesses a particular cluster. On subsequent logins, just     

    ssh lxplus-cloud.cern.ch

    export KUBECONFIG=[directory to hold cluster files]/config

You can now issue all kubectl commands mentioned below as well as run the upgrade scripts.

# First time setup

## OpenStack project

You need to request a personal OpenStack project in which to install your kubernetes cluster. 
You might also want to request a quota for "Shares" in the "Geneva CephFS Testing" type for persistent data storage. 
This is used right now by Graphite.

## Setup a new cluster in the CMSRucio project:

Begin by logging into the CERN cloud infrastructure `slogin lxplus7-cloud.cern.ch` then:

    openstack coe cluster delete --os-project-name CMSRucio  cmsruciotest
    # openstack coe cluster create cmsruciotest --keypair lxplus  --os-project-name CMSRucio   --cluster-template kubernetes-preview --node-count 4
    
    # Currently the the command is this one
    # one must specify all the labels, even the unchanged ones, which can be found via:
    # openstack --os-project-name CMSRucio coe cluster template show kubernetes-1.13.3-1
    openstack coe cluster create [CLUSTERNAME] --keypair lxplus --os-project-name CMSRucio --cluster-template kubernetes-1.13.3-1 --node-count 5 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_csi_version=v0.3.0,cvmfs_tag=qa,cephfs_csi_enabled=True,cephfs_csi_version=v0.3.0,manila_enabled=True,manila_version=v0.3.0,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,influx_grafana_dashboard_enabled=True --master-flavor m2.small    
    openstack coe cluster list --os-project-name CMSRucio # Monitor creation status

Note: Fold in http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/lb.html with additional labels which probably also gets rid of the need to install helm directly as well as the nginx install.

If you are creating your own project for development, please omit `--os-project-name CMSRucio`. 
This will create a kubernetes cluster in your own openstack space rather than the central group space.
CMSRucio is a project space CERN has setup for us to contain our production and testbed servers.

### If setting up a new/changed cluster:

    cd [some directory] # or use $HOME
    export BASEDIR=`pwd`
    rm key.pem cert.pem ca.pem config
    openstack coe cluster config  --os-project-name CMSRucio  cmsruciotest
    
This command will show you the proper value of your `KUBECONFIG` variable which should be this:   
    
    export KUBECONFIG=$BASEDIR/config

Copy and paste the last line. On subsequent logins it is all that is needed. Now make sure that your nodes exist:

    -bash-4.2$ kubectl get nodes
    NAME                                 STATUS    ROLES     AGE       VERSION
    cmsruciotest-mzvha4weztri-minion-0   Ready     <none>    5m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-1   Ready     <none>    6m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-2   Ready     <none>    6m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-3   Ready     <none>    6m        v1.11.2

## Setup the helm repos if needed

    kubectl config current-context
    helm repo add rucio https://rucio.github.io/helm-charts
    helm repo add kiwigrid https://kiwigrid.github.io

## Setup StorageClass (if needed)

If we have CephFS storage needs, one makes a single storage class for the entire claim:

    kubectl create -f cms-rucio-storage.yaml

## Install helm into the kubernetes project

    cd CMSKubernetes/kubernetes/rucio
    ./install_helm.sh

## Get a host certificate for the server

Go to ca.cern.ch and get the host certificate for one of the load balanced names above. 
Add Service alternate names for the load balanced hostname, e.g. cms-rucio-auth-dev.cern.ch and cms-rucio-auth-dev

## Create relevant secrets 

Set the following environment variables. The filenames must match these exactly.

    cd CMSKubernetes/kubernetes/rucio
    export HOSTP12=[path to host cert for ]-minion-0.p12 
    export ROBOTCERT=[path to robot cert]/usercert.pem
    export ROBOTKEY=[path to unencrypted robot]/new_userkey.pem
    ./create_secrets.sh

*This needs to be relocated
    ./CMSKubernetes/kubernetes/rucio/rucio_reaper_secret.sh  # Currently needs to be done after helm install below 
 *

N.b. In the past we also used /etc/pki/tls/certs/CERN-bundle.pem as a volume mount for logstash. 
That no longer seems to be needed.

## Install CMS server into the kubernetes project. Later we can add another set of values files for testbed, integration, production

    export KUBECONFIG=[as above]
    cd CMSKubernetes/kubernetes/rucio
    ./install_rucio_[production, testbed, etc].sh

# To upgrade the servers

The above is what is needed to get things bootstrapped the first time. After this, you can modify the various yaml files and

    export KUBECONFIG=[as above]
    cd CMSKubernetes/kubernetes/rucio
    ./upgrade_rucio_[production, testbed, etc].sh
    
# Get a client running and connect to your server

There are two ways of doing this. 
The first is best for most people and involves setting up a VM inside CERN with docker installed. 
Instructions are at https://github.com/dmwm/CMSRucio/wiki/Setting-up-a-VM-as-a-client

You can also install, into k8s, another pod running a client installed to connect to your new server. 
There is a client YAML file which is used for this. 
Find the client name below from the output of `kubectl get pods`

    kubectl create -f rucio-client.yaml 
    kubectl get pods
    kubectl exec -it client-6c4466d746-gwl9g /bin/bash
    
And then in your client container, setup a proxy or use user/password etc. and
    
    export RUCIO_ACCOUNT=[an account your identity maps to]
    rucio whoami 

From here you should be able to use any rucio command line commands you need to.

# Connect to graphite from a web browser

This is complicated at the moment. One needs to figure out what node the server is exposed on using kubectl tools and 
use tunneling if connecting from outside of CERN. 

Setup the tunnel with 

    ssh -D 8089 -N ${USER}@lxplus.cern.ch

and configure your browser appropriately (Firefox works well with SOCK5 proxies) then visit the URL for the graphite server
which at the time of writing was http://cmsruciotest-73m6rlb5qg4p-minion-3.cern.ch:30862 

# Decommission a cluster

It's probably best to do this in a controlled fashion. First remove any DNS aliases from the cluster:

    openstack server unset  --property landb-alias --os-project-name CMSRucio cmsruciotestbed-ga3x5mujvho7-minion-0 
    openstack server unset  --property landb-alias --os-project-name CMSRucio cmsruciotestbed-ga3x5mujvho7-minion-1 
    ...
    
Then wait 30-60 minutes for DNS to reflect this removal. Then you can delete the cluster with 

    openstack coe cluster delete --os-project-name CMSRucio  MYOLDCLUSTER
    
or remove the kubernetes parts of the cluster and THEN delete the cluster

    helm del --purge cms-rucio-testbed cms-ruciod-testbed filebeat logstash graphite 
    openstack coe cluster delete --os-project-name CMSRucio  MYOLDCLUSTER
    
