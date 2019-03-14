### cmsweb k8s app
To create cmsweb app on kubernetes cluster please follow these steps:

1. create new cluster by login to `lxplus-cloud.cern.ch` and execute the
   following command (use one of them, they are listed as an example)

```
# create new cluster
openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,flannel_backend=vxlan,ingress_controller=traefik

# create new cluster
openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=traefik

# create new cluster with specific flavor and number of nodes
openstack --os-project-name "CMS Webtools Mig" coe cluster create cmsweb --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=traefik --flavor m2.2xlarge --node-count 2
```

You will need to wait once cluster is created. You may verify its existence
with this command:
```
openstack --os-project-name "CMS Webtools Mig" coe cluster list
# it should have CREATE_COMPLETE status
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
# this command didn't work for me but was listed in CERN IT instructions
openstack server set --property landb-alias=cmsweb-test cmsweb-test-sds42p2lfiup-minion-0

# create new tiller-rbac.yaml file
# see example on http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/helm.html

# create new tiller resource
kubectl create -f tiller-rbac.yaml

# init tiller
helm init --service-account tiller --upgrade

# delete previous ingress-traefik
kubectl -n kube-system delete ds/ingress-traefik

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

# get list of pods in kube-system namespace, here we should see traefik controller
kubectl get pods -n kube-system
...
# we should see cluster name and traefik Running status
ingress-traefik-lk85w                   1/1       Running            0  15h


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


### Troubleshooting
If you find that some of the pods didn't start you may use the following
commands to trace down the problem:
```
# get list of pods, secrets, ingress
kubectl get pods
kubectl get secrets
kubectl get ing

# get description of pod,secret,ingress
kubectl describe pod/<pod_name>
kubectl describe ing/<ingress_name>
kubectl describe secrets/<secret_name>

# get log information from the pod
kubectl logs <pod_name>

# if necessary you can login to your pod as following:
kubectl exec -ti <pod_name> bash
# here is a concrete example
kubectl exec -ti httpsgo-deployment-5b654d8f99-lfmg5 bash
```
