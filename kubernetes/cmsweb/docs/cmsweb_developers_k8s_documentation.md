## Developers Cluster

There are three clusters in “CMS Webtools Mig” project which are available for developers to test their services. The URLs to access these clusters are listed below:

- https://cmsweb-test1.cern.ch
- https://cmsweb-test2.cern.ch
- https://cmsweb-test3.cern.ch

These cluster will be shared and anyone will have full access, therefore people should coordinate and/or plan accordingly. 
For example, our suggestions are listed below:

- cmsweb-test1 should be used by DMWM team
- cmsweb-test2 should be used by CRAB team
- cmsweb-test3 should be used by DBS team

Users may request a new cluster or its redeployment in [https://gitlab.cern.ch/cms-http-group/doc/issues/196](https://gitlab.cern.ch/cms-http-group/doc/issues/196) forum. 

## Build Service Container for K8s cluster:

#### Build RPMs
- go to the build node
   - `ssh vocms055`
   - `cd /buid/belforte/cmsdist`
- git fetch/merge/update as needed
- now change service version as needed/usual
   - `vim xxx.spec`
- build and upload
   - `cd /build/belforte`
   - `pkgtools/cmsBuild -c cmsdist --repository comp -a slc7_amd64_gcc630 --builders 8 -j 5 --work-dir w build comp`
   - `pkgtools/cmsBuild -c cmsdist --repository comp -a slc7_amd64_gcc630 --builders 8 -j 5 --work-dir w --upload-user=$USER upload comp`
- note the HG version and service etc. version in the rpms
   - e.g. at http://cmsrep.cern.ch/cmssw/repos/comp.belforte/slc7_amd64_gcc630/latest/RPMS.json
- or with
   - `ls w/BUILD/slc7_amd64_gcc630/cms/comp/|tail -1`
   - etc. replacing comp with crabserver, crabcache etc
- or all in one shot
   - `for pkg in `ls w/BUILD/slc7_amd64_gcc630/cms/`; do iecho $pkg; ls -lgort w/BUILD/slc7_amd64_gcc630/cms/$pkg/|tail -1; done`

#### Build Container (replaces the installation on VM)
- go to the build node (ask Shahzad for access)
   - `ssh cmsdocker01`
- go to the director where you have cloned https://github.com/dmwm/CMSKubernetes (or your fork of it)
   - `cd ~/WORK/GIT/CMSKubernetes/docker/`
- git fetch/merge/update as needed
- now change VER and REPO e.g .to VER=HG1911a-comp and REPO=comp.belforte
   - `vim crabserver/install.sh`
- build and tag the container with the version for the crabserver which is inside that rpm
   - `docker build --build-arg CMSK8S=http://cmsweb-test1.web.cern.ch -t sbelforte/crabserver:3.3.1911.rc2 crabserver`
- check with e.g.
   - `docker images`
   - `docker inspect sbelforte/crabserver:3.3.1911.rc2`
   - `docker inspect <IMAGE ID> # where <IMAGE ID> is from docker images output`
   - `docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t sbelforte/crabserver:3.3.1911.rc2 /bin/bash`
- the latter command logs you in the container and where can examine the /data/srv tree
- push to docker
   - docker push sbelforte/crabserver:3.3.1911.rc2
- cleanup (IMAGE ID is from docker images )
   - `docker rmi <IMAGE ID>`
- Find more docker commands in https://github.com/dmwm/CMSKubernetes/blob/master/docker/README.md
   - in particular note that running containers may keep running after you logout, use docker ps to find the CONTAINER ID and docker stop <CONTAINER ID> to stop it
   
## Service Deployment Steps in K8S:

- `ssh lxplus-cloud`
- `export OS_PROJECT_NAME="CMS Webtools Mig"`

Use export KUBECONFIG to point to the relevant configurations for the clusters. Please note that these configurations are for the backend clusters as users will only need to work in the backend clusters to deploy/undeploy their services. However, if any user need access to the frontend configuration, we can provide this on demand. The KUBECONFIG for the backend are listed below:  

- `export KUBECONFIG=/afs/cern.ch/user/m/mimran/public/cmsweb-k8s/config.cmsweb-srv1`
   - This configuration will be used for host cmsweb-test1.cern.ch
- `export KUBECONFIG=/afs/cern.ch/user/m/mimran/public/cmsweb-k8s/config.cmsweb-srv2`
   - This configuration will be used for host cmsweb-test2.cern.ch
- `export KUBECONFIG=/afs/cern.ch/user/m/mimran/public/cmsweb-k8s/config.cmsweb-srv3`
   - This configuration will be used for host cmsweb-test3.cern.ch

To see all services and their status, following command can be used:
   - `kubectl get pods --all-namespaces`

For example, following are the namespaces available in this cluster. 

   - `kubectl get ns`
```
NAME            STATUS   AGE
confdb          Active   20h
couchdb         Active   20h
crab            Active   20h
das             Active   20h
dbs             Active   20h
default         Active   21h
dmwm            Active   20h
dqm             Active   20h
http            Active   20h
kube-public     Active   21h
kube-system     Active   21h
magnum-tiller   Active   21h
monitoring      Active   20h
phedex          Active   20h
tfaas           Active   20h
tzero           Active   20h
```
To get information of specific namespace, use:

   - `kubectl get pod -n confdb`

   - `kubectl get pod -n crab`

To deploy new service, the service first needs to be deleted and then redeployed. Following commands can be used for this purpose. 
- Clone this repository:

   - `git clone https://github.com/dmwm/CMSKubernetes.git`

- Go into CMSKubernetes/kubernetes/cmsweb-nginx directory:

- Update yaml file with the new version For example open relevant service file (xxx.yaml e.g crabserver.yaml) and change version:
   - `vim services/xxx.yaml`

- Deploy newly changed yaml file. First delete old service from K8S and deploy new one. For example: 

   - `kubectl delete -f services/xxx.yaml`
   - `kubectl apply -f services/xxx.yaml --validate=false`

- check that /data/srv/current points to correct version
   - `ls -l /data/srv/current`
   - `ls  /data/srv/current/sw/slc7_amd64_gcc630/cms/xxx/`
   
## Book keeping

- remember to write e-log entry
   - https://cms-logbook.cern.ch/elog/Analysis+Operations/?cmd=New
- make a PR for CMSKubernetes GIT so that it stays up to date on which image should be deployed
   - example: https://github.com/dmwm/CMSKubernetes/pull/80

