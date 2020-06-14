## CMSWeb Testbed Cluster

There is a new testbed cluster in kuberneteds for CMSWeb in "CMS Web" project which is now available for developers to test their services. The URL to access this cluster is listed below:

- https://cmsweb-k8s-testbed.cern.ch

Users/developers may request for access of this cluster in their namespace in [https://gitlab.cern.ch/cms-http-group/doc/issues/199](https://gitlab.cern.ch/cms-http-group/doc/issues/199) forum. 

Logs or application running ont this cluster are directed to CEPHS volume and accessible in real time on vocms0750 at /cephfs/testbed

   
## Service Deployment Steps in K8S testbed cluster:

- `ssh lxplus-cloud`

Use export KUBECONFIG to point to the relevant configurations for the clusters. Please note that these configurations are for the backend clusters as users will only need to work in the backend clusters to deploy/undeploy their services. The configuration file for backend cluster can be downloaded from [here](https://cernbox.cern.ch/index.php/s/Fnxcj4x3sUm92cs/download)

- `wget https://cernbox.cern.ch/index.php/s/Fnxcj4x3sUm92cs/download -O config.cmsweb-k8s-services-testbed`
- `export OS_TOKEN=$(openstack token issue -c id -f value)`
- `export KUBECONFIG=$PWD/config.cmsweb-k8s-services-testbed`
 
To see all pods in a particular namespace, following command can be used:
   - `kubectl -n <namespace> get pods`

To login to a specific pod, use:

   - `kubectl -n <namespace> exec -ti <pod-name> bash`

To delete a pod, use:
   - `kubectl -n <namespace> delete pod/<pod-name>`

To force delete a pod if above command does not work, use:
   - `kubectl -n <namespace> delete pod/<pod-name> --force --grace-period=0`

To deploy new service, the service first needs to be deleted and then redeployed. Following commands can be used for this purpose. 
- Clone this repository:

   - `git clone https://github.com/dmwm/CMSKubernetes.git`

- Go into CMSKubernetes/kubernetes/cmsweb directory:

- Update yaml file with the new version. For example open relevant service file (xxx.yaml e.g crabserver.yaml) and change version:
   - `vim services/xxx.yaml`

- Deploy newly changed yaml file. First delete old service from K8S and deploy new one. For example: 

   - `kubectl delete -f services/xxx.yaml`
   
 - Then, following command can be used to deploy service in testbed cluster. 
  - 
   ```
   cat services/xxx.yaml | sed -e "s,1 #PROD#,,g" | sed -e "s,#PROD#,      ,g" | sed -e "s,logs-cephfs-claim,logs-cephfs-claim-preprod,g" | kubectl apply -f -
   ```

 - Please note that string #PROD# should be replaced by six spaces and logs-cephfs-claim should be replaced by logs-cephfs-claim-preprod for testbed cluster as shown above in the command.


## CMSWEB Testbed Cluster Monitoring

There are monitoring pages for CMSWEB k8s testbed clusters in `https://monit-grafana.cern.ch` 

- The URL to access frontend cluster is available [here](https://monit-grafana.cern.ch/d/cmsweb-k8s-testbed-frontend/cmsweb-k8s-testbed-frontends?orgId=11&refresh=30s)

- The URL to access backend cluster is available [here](https://monit-grafana.cern.ch/d/cmsweb-k8s-testbed-services/cmsweb-k8s-testbed-services?orgId=11&refresh=30s)

These webpages provide cluster and pod resource usage in terms of `RAM` and `CPU`. 

 
