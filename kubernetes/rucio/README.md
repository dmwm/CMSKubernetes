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
To use CMSWeb project space, issue this command; skip it to use your own.
CMSRucio is a project space CERN has set up for us to contain our testbed servers.

    export OS_PROJECT_NAME=CMSRucio

Get the latest copy of `https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/scripts/create_templates_dev.sh` 
edit and run as needed to create a template used for your cluster. Then create a cluster with a command like:
    
    openstack coe cluster create --keypair lxplus --cluster-template TEMPLATE --master-count 1 --node-count NUMBER CLUSTER_NAME 

You can monitor the status of the cluster creation with
    
    openstack coe cluster list

Once it is finished, generate the KUBECONFIG file as explained above 
and run the script `create_network.sh` to set the LANDB aliases.

### Get a host certificate for the server

You may need to wait a few minutes for this to be possible as things percolate through DNS and LANDB.
Go to ca.cern.ch and get the host certificate for one of the load balanced names above. 
Add Service alternate names for the load balanced hostname, e.g. 
 * cms-rucio-testbed
 * cms-rucio-auth-testbed
 * cms-rucio-webui-testbed
 * cms-rucio-stats-testbed
 * cms-rucio-trace-testbed
 * cms-rucio-eagle-testbed
 
 For clusters created by the Cat-A, this certificate will be provided as part of the process. 
  
# Working with the cluster

Once you have the correct value of KUBECONFIG set you should check that you can view the cluster like like so:

    -bash-4.2$ kubectl get nodes
    NAME                                 STATUS    ROLES     AGE       VERSION
    cmsruciotest-mzvha4weztri-minion-0   Ready     <none>    5m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-1   Ready     <none>    6m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-2   Ready     <none>    6m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-3   Ready     <none>    6m        v1.11.2

## Setup the helm repos if needed

We have switched to helm3 which no longer requires a pod running in the kubernetes cluster. 
To distinguish this, place the helm3 executable named helm3 in your path. 
You can download a copy from https://github.com/helm/helm/releases (make sure you find the latest version 3 release). 

Substitute helm3 for helm

    helm3 repo add rucio https://rucio.github.io/helm-charts
    helm3 repo add cms-kubernetes https://dmwm.github.io/CMSKubernetes/helm/
    helm3 repo add kube-eagle https://raw.githubusercontent.com/cloudworkz/kube-eagle-helm-chart/master

## Create relevant secrets 

Set the following environment variables. The filenames must match these exactly.

    cd CMSKubernetes/kubernetes/rucio
    export INSTANCE=dev{,int,testbed,prod}
    export HOSTP12=[path to host cert for ]-minion|node-0.p12 
    export ROBOTP12=[path to robot cert].p12
    ./create_secrets.sh

## Install CMS server into the kubernetes project. 

    export KUBECONFIG=[as above]
    cd CMSKubernetes/kubernetes/rucio
    ./install_rucio_[production, testbed, etc].sh

# To upgrade the servers

The above is what is needed to get things bootstrapped the first time. 

You can fetch new helm charts with the command
    
    helm3 repo update

So that you are running the most recent versions of configurations of all the software. 
To make your own changes to the Rucio setup, modify the various yaml files and

    export KUBECONFIG=[as above]
    cd CMSKubernetes/kubernetes/rucio
    ./upgrade_rucio_[production, testbed, etc].sh
    
Sometimes it's easiest just to set up a few environment variables and execute the relevant commands.    
    
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

    helm3 del --purge cms-rucio-testbed cms-ruciod-testbed filebeat logstash graphite 
    openstack coe cluster delete --os-project-name CMSRucio  MYOLDCLUSTER
    
