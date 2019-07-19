### cmsweb k8s app
To create cmsweb app on kubernetes cluster please follow these steps:

1. create new cluster by login to `lxplus-cloud.cern.ch` and execute the
   following command (use one of them, they are listed as an example)

```
# create new cluster
openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true

# create new cluster with specific flavor and number of nodes
openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true --flavor m2.2xlarge --node-count 2

openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.14.1-1 --labels cern_enabled=True,kube_tag=v1.14.1,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true,manila_enabled=True,manila_version=v0.3.0,heat_container_agent_tag=stein-dev-1 --flavor m2.2xlarge --node-count 2

openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-2 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=nginx,cern_tag=qa,tiller_enabled=true,manila_enabled=True,manila_version=v0.3.0,heat_container_agent_tag=stein-dev-1 --flavor m2.2xlarge --node-count 2

# large template
openstack coe cluster template create cmsweb-template-2xlarge --labels influx_grafana_dashboard_enabled="true" --labels ingress_controller="nginx" --labels tiller_enabled=true --labels kube_csi_enabled="true" --labels kube_csi_version="v0.3.2" --labels kube_tag="v1.13.3-12" --labels container_infra_prefix="gitlab-registry.cern.ch/cloud/atomic-system-containers/" --labels manila_enabled="true" --labels cgroup_driver="cgroupfs" --labels cephfs_csi_enabled="true" --labels cvmfs_csi_version="v0.3.0" --labels admission_control_list="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority" --labels flannel_backend="vxlan" --labels manila_version="v0.3.0" --labels cvmfs_csi_enabled="true" --labels cvmfs_tag="qa" --labels cephfs_csi_version="v0.3.0" --labels cern_enabled="true" --coe kubernetes --image 26666ca8-bda9-4356-982f-4a92845ec361 --external-network CERN_NETWORK --fixed-network CERN_NETWORK --network-driver flannel --dns-nameserver 137.138.17.5 --flavor m2.2xlarge --master-flavor m2.medium --docker-storage-driver overlay2 --server-type vm

# create new template
openstack coe cluster template create cmsweb-template-medium --labels influx_grafana_dashboard_enabled="true" --labels ingress_controller="nginx" --labels tiller_enabled=true --labels kube_csi_enabled="true" --labels kube_csi_version="v0.3.2" --labels kube_tag="v1.13.3-12" --labels container_infra_prefix="gitlab-registry.cern.ch/cloud/atomic-system-containers/" --labels manila_enabled="true" --labels cgroup_driver="cgroupfs" --labels cephfs_csi_enabled="true" --labels cvmfs_csi_version="v0.3.0" --labels admission_control_list="NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,Priority" --labels flannel_backend="vxlan" --labels manila_version="v0.3.0" --labels cvmfs_csi_enabled="true" --labels cvmfs_tag="qa" --labels cephfs_csi_version="v0.3.0" --labels cern_enabled="true" --coe kubernetes --image 26666ca8-bda9-4356-982f-4a92845ec361 --external-network CERN_NETWORK --fixed-network CERN_NETWORK --network-driver flannel --dns-nameserver 137.138.17.5 --flavor m2.medium --master-flavor m2.medium --docker-storage-driver overlay2 --server-type vm

# manage templates
openstack --os-project-name "CMS Webtools Mig" coe cluster template list
openstack --os-project-name "CMS Webtools Mig" coe cluster template delete 89073ecc-d416-452f-84a9-278612b63d1e
openstack --os-project-name "CMS Webtools Mig" coe cluster create --keypair cloud --cluster-template cmsweb-template-2xlarge cmsweb

# update cluster, to use 4 nodes
openstack --os-project-name "CMS Webtools Mig" coe cluster update cmsweb replace node_count=4
```

You will need to wait once cluster is created. You may verify its existence
with this command:
```
openstack --os-project-name "CMS Webtools Mig" coe cluster list
# it should have CREATE_COMPLETE status
```

We can also create an additional volume, e.g. to store our cmsweb logs, via the
following command:
```
openstack --os-project-name "CMS Webtools Mig" volume create cmsweb_logs --size 50
openstack --os-project-name "CMS Webtools Mig" volume list

# create new cephfs storage
kubectl apply -f storage-cephfs.yaml
# check its quota
kubectl get pvc

# delete storage
kubectl delete -f storage-cephfs.yaml
manila list
manila delete <ID>
kubectl delete pv --all

# check if resources are freed
kubectl get pvc
manila list

```

```
# we need to adjust nginx controller of the cluster to avoid its crashes until
# it is fixed by CERN IT, this can be done by editing its confiugration
# one time operation:
# - remove xxxxxxxProbe section (healthz)
# - increase ram allocation from 64Mi to 128Mi
kubectl -n kube-system edit daemonset.apps/nginx-ingress-controller

# then we can restart the daemon set as following, e.g.
kubectl -n kube-system delete pod nginx-ingress-controller-gsw2b
# or better use this independent from pod name command
kubectl -n kube-system get pods | grep ingress-controller | awk '{print "kubectl -n kube-system delete pod "$1""}'

```

Once cluster is created we need to perform one-time operation to get pem files
and config for it. Just do:
```
# remove previous pem files and configuration
rm *.pem config
# create new pem files and configuration
$(openstack --os-project-name "CMS Webtools Mig" coe cluster config cmsweb)
```

Then go to `https://webservices.web.cern.ch/webservices/` and register new
domain name, e.g. cmsweb, for cluster node we got. We can get cluster node via
the following command:
`
kubectl get node
`

The next series of steps is required until CERN IT will deploy new flag for
ingress nginx controller
```
# set landb alias
# if used personal project name, see echo $OS_PROJECT_NAME
openstack server set --property landb-alias=cmsweb-test cmsweb-test-sds42p2lfiup-minion-0
# if used specific project name, e.g. "CMS Webtools Mig"
openstack server set --os-project-name "CMS Webtools Mig" --property landb-alias=cmsweb-test cmsweb-p4yxjed3kfjv-minion-0

# create new tiller-rbac.yaml file
# see example on http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/helm.html

# create new tiller resource
kubectl create -f tiller-rbac.yaml

# init tiller
helm init --service-account tiller --upgrade

# delete previous ingress-traefik, NO LONGER NEEDED when we create cluster with nginx ingress controller
# kubectl -n kube-system delete ds/ingress-traefik

# install tiller
helm init --history-max 200
helm install stable/nginx-ingress --namespace kube-system --name ingress-nginx --set rbac.create=true --values nginx-values.yaml
```


2. Now, we can deploy our k8s app using `deploy.sh` script. You may verify apps
   creation by using these commands:
```
# get list of pods (deployed apps) in default namespace
# here we should get cmsweb app deployed
kubectl get pods
...
# we should see cluster name and Running status
cmsweb-5556f46d6c-phkmq   1/1       Running   0          15h

# get list of pods in kube-system namespace, here we should see traefik/nginx controllers
kubectl get pods -n kube-system
...
# we should see cluster name and traefik/nginx Running status
# example of traefik ingress
ingress-traefik-lk85w                   1/1       Running            0  15h
# example of nginx ingress
ingress-nginx-nginx-ingress-controller-qv8vj                   1/1 Running   0          18d
ingress-nginx-nginx-ingress-default-backend-85474bb488-5s8mb   1/1 Running   0          18d

# get list of deployed services, here we should see our cmsweb with port 80
kubectl get svc
...
# we should see hostname and port mapping
cmsweb       NodePort    10.254.136.150   <none>        8181:30181/TCP   15h
```

3. create new DNS alias at `https://webservices.web.cern.ch/webservices/`
using our k8s node name which we can obtain via `kubectl get node` command.
Use this name with .cern.ch suffix to create a DNS alias we need, e.g.
`cmsweb`. The new DNS alias will be accessible as `<aliasName>.web.cern.ch`

4. check that new service is running, e.g. call `curl http://cmsweb.web.cern.ch`

### Additional features

- [Load balancing](https://clouddocs.web.cern.ch/clouddocs/containers/tutorials/lb.html)
- [Autoscale](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale)
- [Using configmap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap)
- [Using secrets](https://kubernetes.io/docs/concepts/configuration/secret)
- [Accessing pods](http://alesnosek.com/blog/2017/02/14/accessing-kubernetes-pods-from-outside-of-the-cluster)
- [DNS for pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service)
- [Logging](https://kubernetes.io/docs/concepts/cluster-administration/logging/)

### Troubleshooting
If you find that some of the pods didn't start you may use the following
commands to trace down the problem:
```
# get list of pods, secrets, ingress
kubectl get pods
kubectl get secrets
kubectl get ing

# Please note there are multiple namespace, default one, kube-system
# where all network controllers are and additional ones like monitoring
# you can inspect pods, secrets, etc in these namespace by using -n flag, e.g.
kubectl -n kube-system get pods

# get description of pod,secret,ingress
kubectl describe pod/<pod_name>
kubectl describe ing/<ingress_name>
kubectl describe secrets/<secret_name>

# get log information from the pod
kubectl logs <pod_name>
# here is concrete example of producing logs from ingress-nginx in kube-system namespace
kubectl -n kube-system logs ingress-nginx-nginx-ingress-controller-s2rrk

# if necessary you can login to your pod as following:
kubectl exec -ti <pod_name> bash
# here is a concrete example
kubectl exec -ti httpsgo-deployment-5b654d8f99-lfmg5 bash

# you can login into your minion node too, e.g.
# obtain minion name
kubectl get node | grep minion

# with that name login to it as following (change your ssh file you used to
# create k8s and substitute the minion_name
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@<minion_name>
```
