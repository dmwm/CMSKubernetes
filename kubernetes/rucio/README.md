Adapted from rucio instructions here: https://github.com/rucio/helm-charts/tree/master/rucio-server

# Accessing the existing kubernetes clusters

Most people will only need to access an existing cluster to view logs, change configs, etc. 
For development clusters, these are in the CMSRucio Openstack project space, 
so one can generate a copy if one does not have it.

    ssh lxplus-cloud.cern.ch

    mkdir [directory to hold cluster config file]
    cd [directory to hold cluster config file]
    `openstack coe cluster config  --os-project-name CMSRucio [cluster name, eg. cmsruciodev1]`
    
even that is only needed the first time one accesses a particular cluster. On subsequent logins, just     

    ssh lxplus-cloud.cern.ch

    export KUBECONFIG=[directory made above]/config

For integration and production clusters, these are made by the CMSWeb Cat-A. 
You need to be given the correct config file and it must be kept safe (not readable by anyone other than you.)

    export KUBECONFIG=/path/to/cluster/config

You can now issue all kubectl commands mentioned below as well as run the upgrade scripts.

# Creating your own cluster (most should skip this section)

## OpenStack project

You need to request a personal OpenStack project in which to install your kubernetes cluster or get access to the CMSRucio 
project space. 
You might also want to request a quota for "Shares" in the "Geneva CephFS Testing" type for persistent data storage. 
This is used right now by Graphite.

## Setup a new cluster in the CMSRucio project:

Begin by logging into the CERN cloud infrastructure `slogin lxplus7-cloud.cern.ch`. 

    export OS_PROJECT_NAME=CMSRucio

Get the latest copy of `https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/scripts/create_templates_dev.sh` 
edit and run as needed to create a template used for your cluster. Then create a cluster with a command like:
    
    openstack coe cluster create  --os-project-name CMSRucio --keypair lxplus --cluster-template TEMPLATE --master-count 1 --node-count NUMBER CLUSTER_NAME 

If you are creating your own project for development, please omit `--os-project-name CMSRucio`. 
This will create a kubernetes cluster in your own openstack space rather than the central group space.
CMSRucio is a project space CERN has set up for us to contain our testbed servers.

### If setting up a new/changed cluster:

For centrally managed cluster, get config file from Cat-A or ...

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

Substitute helm3 for helm

    # kubectl config current-context
    helm repo add rucio https://rucio.github.io/helm-charts
    # helm repo add kiwigrid https://kiwigrid.github.io
    helm repo add cms-kubernetes https://dmwm.github.io/CMSKubernetes/helm/
    helm repo add kube-eagle https://raw.githubusercontent.com/cloudworkz/kube-eagle-helm-chart/master

## Install helm into the kubernetes project

Not needed with helm3. Skip.

This is needed even though CERN installs its own helm to manage ingress-nginx. 
The two helm instances are in separate k8s namespaces, so they do not collide.

    cd CMSKubernetes/kubernetes/rucio
    ./install_helm.sh

## Get a host certificate for the server

Go to ca.cern.ch and get the host certificate for one of the load balanced names above. 
Add Service alternate names for the load balanced hostname, e.g. 
 * cms-rucio-testbed
 * cms-rucio-auth-testbed
 * cms-rucio-webui-testbed
 * cms-rucio-stats-testbed
 * cms-rucio-trace-testbed
 * cms-rucio-eagle-testbed

## Create relevant secrets 

Set the following environment variables. The filenames must match these exactly.

    cd CMSKubernetes/kubernetes/rucio
    export HOSTP12=[path to host cert for ]-minion|node-0.p12 
    export ROBOTCERT=[path to robot cert]/usercert.pem
    export ROBOTKEY=[path to unencrypted robot]/new_userkey.pem
    ./create_secrets.sh

*Obsolete?
    ./CMSKubernetes/kubernetes/rucio/rucio_reaper_secret.sh  # Currently needs to be done after helm install below 
 N.b. In the past we also used /etc/pki/tls/certs/CERN-bundle.pem as a volume mount for logstash. 
That no longer seems to be needed.*

## Install CMS server into the kubernetes project. Later we can add another set of values files for testbed, integration, production

    export KUBECONFIG=[as above]
    cd CMSKubernetes/kubernetes/rucio
    ./install_rucio_[production, testbed, etc].sh

# To upgrade the servers

The above is what is needed to get things bootstrapped the first time. After this, you can modify the various yaml files and

    export KUBECONFIG=[as above]
    cd CMSKubernetes/kubernetes/rucio
    ./upgrade_rucio_[production, testbed, etc].sh
    
# Resizing a cluster

You can add or subtract nodes with the following command
    
    openstack coe cluster update [cluster_name] --os-project-name CMSRucio replace node_count=[new_count]
    
# Get a client running and connect to your server

There are lots of ways of doing this, but the easiest now is to use the CMS installed Rucio from CVMFS. 
Note that the python environment can clash with openstack, so best to use a new window.

     source /cvmfs/cms.cern.ch/rucio/setup.sh

You will also need to setup a config file pointed to by RUCIO_HOME.

You can also run the rucio client in a container or even in the k8s cluster. 
Instructions for these methods are no longer provided.

Then setup a proxy and
    
    export RUCIO_ACCOUNT=[an account your identity maps to]
    rucio whoami 

From here you should be able to use any rucio command line commands you need to.

# Decommission a cluster

It's probably best to do this in a controlled fashion. 
You can run the teardown_dns.sh script or remove any DNS aliases manually from the cluster:

    openstack server unset  --property landb-alias --os-project-name CMSRucio cmsruciotestbed-ga3x5mujvho7-minion-0 
    openstack server unset  --property landb-alias --os-project-name CMSRucio cmsruciotestbed-ga3x5mujvho7-minion-1 
    ...
    
Then wait 30-60 minutes for DNS to reflect this removal. 
Make sure you can access the new cluster with the Rucio client.
Then you can delete the cluster with 

    openstack coe cluster delete --os-project-name CMSRucio  MYOLDCLUSTER
    
or remove the kubernetes parts of the cluster and THEN delete the cluster

    helm del --purge cms-rucio-testbed cms-ruciod-testbed filebeat logstash graphite 
    openstack coe cluster delete --os-project-name CMSRucio  MYOLDCLUSTER
    
