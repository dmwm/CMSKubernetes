Adapted from rucio instructions here: https://github.com/rucio/helm-charts/tree/master/rucio-server


# First time setup

## Setup a new cluster in the CMSRucio project:

Begin by logging into the CERN cloud infrastructure `slogin lxplus7-cloud.cern.ch` then:

    openstack coe cluster delete --os-project-name CMSRucio  cmsruciotest
    openstack coe cluster create cmsruciotest --keypair lxplus  --os-project-name CMSRucio   --cluster-template kubernetes-preview --node-count 4
    openstack coe cluster list --os-project-name CMSRucio # Monitor creation status

Note that you can set up a cluster in your personal project space by omitting `--os-project-name CMSRucio`. 
CMSRucio is a project space CERN has setup for us to contain our production and testbed servers.

### If setting up a new/changed cluster:

    cd [some directory] # or use $HOME
    export BASEDIR=`pwd`
    rm key.pem cert.pem ca.pem config
    openstack coe cluster config  --os-project-name CMSRucio  cmsruciotest
    
This command will show you the proper value of your `KUBECONFIG` variable which should be this:   
    
    export KUBECONFIG=$BASEDIR/config


Copy and paste the last line. On subsequent logins it is all that is needed. Now make sure that your nodes exist:

    -bash-4.2$ export KUBECONFIG=[as above]
    -bash-4.2$ kubectl get nodes
    NAME                                 STATUS    ROLES     AGE       VERSION
    cmsruciotest-mzvha4weztri-minion-0   Ready     <none>    5m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-1   Ready     <none>    6m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-2   Ready     <none>    6m        v1.11.2
    cmsruciotest-mzvha4weztri-minion-3   Ready     <none>    6m        v1.11.2

## Install helm if needed

Download helm using instructions at https://docs.helm.sh/using_helm/#installing-helm and install it in your path like:

    mkdir $HOME/bin
    export PATH=$PATH:$HOME/bin
    cp helm $HOME/bin

## Setup helm if needed

    export KUBECONFIG=[as above]
    kubectl config current-context
    helm repo add rucio https://rucio.github.io/helm-charts

## Label nodes for ingress and add the same nodes to the DNS registration

Pick at least two of the nodes from the output of the `kubectl get nodes` command above. (Two for load balancing/redundancy.)

    kubectl label node cmsruciotest-mzvha4weztri-minion-0 role=ingress
    kubectl label node cmsruciotest-mzvha4weztri-minion-3 role=ingress
    openstack server set  --os-project-name CMSRucio  --property landb-alias=cms-rucio-test--load-1- cmsruciotest-73m6rlb5qg4p-minion-0 
    openstack server set  --os-project-name CMSRucio  --property landb-alias=cms-rucio-test--load-2- cmsruciotest-73m6rlb5qg4p-minion-3

`openstack server unset` will undo this. More details are here: https://clouddocs.web.cern.ch/clouddocs/containers/tutorials/lb.html

## Install helm into the kubernetes project

    helm init
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

## Create relevant secrets 

run `CMSKubernetes/kubernetes/rucio/renew_fts_proxy.sh` on `cms-rucio-authz` node to make the secret `cms-ruciod-testbed-rucio-x509up`.

Create the other secrets with (on lxplus7-cloud.cern.ch):

    kubectl create secret generic  cms-ruciod-testbed-rucio-ca-bundle --from-file=/etc/pki/tls/certs/CERN-bundle.pem
    ./CMSKubernetes/kubernetes/rucio/renew_fts_proxy.sh/rucio_reaper_secret.sh 
    kubectl get secrets

## Install CMS server into the kubernetes project. Later we can add another set of values files for testbed, integration, production

helm install --name cms-rucio-testbed --values cms-rucio-common.yaml --values cms-rucio-server.yaml rucio/rucio-server
helm install --name cms-ruciod-testbed --values cms-rucio-common.yaml --values cms-rucio-daemons.yaml rucio/rucio-daemons
helm install --name graphite --values rucio-graphite.yaml  stable/graphite

# To upgrade the servers

The above is what is needed to get things bootstrapped the first time. After this, you can modify the various yaml files and

    export KUBECONFIG=[as above]
    helm upgrade --values cms-rucio-common.yaml --values cms-rucio-server.yaml cms-rucio-testbed rucio/rucio-server
    helm upgrade --values cms-rucio-common.yaml --values cms-rucio-daemons.yaml cms-ruciod-testbed rucio/rucio-daemons
    helm upgrade --values rucio-graphite.yaml graphite stable/graphite 
    
# Use a node outside of kubernetes as an authorization server and to delegate FTS proxies

While we expect that eventually the authorization server will be able to run inside of kubernetes, at the moment it cannot.
This is because of how kubernetes/traefik handles (or doesn't) client certificates. For the moment, it's easiest just to turn 
an OpenStack node into the authorization server. The same VM can be used to manage the FTS proxies.

## Setup the VM node itself

This recipe is for starting with an OpenStack CC7 node which we assume is named `cms-rucio-authz`. The OpenStack "small" type is fine.

### Get a host certificate installed

Use CERN CA https://ca.cern.ch/ca/ to generate a host cert, scp the cert to lxplus:~/.globus/ and then create certificate and key:

    sudo mkdir /etc/grid-security
    sudo openssl pkcs12 -in ~/.globus/cms-rucio-authz.p12  -clcerts -nokeys -out /etc/grid-security/hostcert.pem
    sudo openssl pkcs12 -in ~/.globus/cms-rucio-authz.p12   -nocerts -nodes -out /etc/grid-security/hostkey.pem
    sudo chmod 0600 /etc/grid-security/hostkey.pem

As root (`sudo su`) install some general packages and docker:

    yum install -y yum-utils device-mapper-persistent-data lvm2 nano git
    yum update -y
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce
    systemctl start docker
    systemctl enable docker
    docker run hello-world
    sudo usermod -a -G docker [your user name]
    exit

Also add what's needed to make this also where we generate and delegate proxies. Also to accept proxies for auth server

    sudo yum -y install voms-clients-cpp
    sudo yum -y install http://linuxsoft.cern.ch/wlcg/centos7/x86_64/wlcg-repo-1.0.0-1.el7.noarch.rpm
    sudo curl -o  /etc/yum.repos.d/ca.repo https://raw.githubusercontent.com/rucio/rucio/master/etc/docker/dev/ca.repo
    sudo yum update 
    sudo yum -y install ca-certificates.noarch lcg-CA voms-clients-cpp wlcg-voms-cms fetch-crl fts-rest-cli

## Start (or restart) the docker image

    ./CMSKubernetes/kubernetes/rucio/start_rucio_auth.sh
   
## Delegate proxies

For now this is not in a cron job:

    ./CMSKubernetes/kubernetes/rucio/renew_fts_proxy.sh


# Get a client running and connect to your server

It can be easiest just to create another container with a client installed to connect to your new server. There is a client YAML file
that can also be installed into your newly formed kubernetes cluster. 
Find the client name below from the output of `kubectl get pods`

    kubectl create -f rucio-client.yaml 
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
