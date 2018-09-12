### tfaas k8s app
To create tfaas app on kubernetes cluster please follow these steps:

1. create new cluster by login to `lxplus-cloud.cern.ch` and execute the
   following command

```
openstack --os-project-name "CMS Webtools Mig" coe cluster create tfaas --keypair cloud --cluster-template kubernetes-preview --labels cern_enabled=True,kube_csi_enabled=True,kube_tag=v1.10.1,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=traefik
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
$(openstack --os-project-name "CMS Webtools Mig" coe cluster config tfaas)
```

Then go to `https://webservices.web.cern.ch/webservices/` and register new
domain name, e.g. tfaas, for cluster node we got. We can get cluster node via
the following command:
`
kubectl get node
`

2. Now, we can deploy our k8s app using `deploy.sh` script. You may verify apps
   creation by using these commands:
```
# get list of pods (deployed apps) in default namespace
# here we should get tfaas app deployed
kubectl get pods
...
# we should see cluster name and Running status
tfaas-5556f46d6c-phkmq   1/1       Running   0          15h

# get list of pods in kube-system namespace, here we should see traefik controller
kubectl get pods -n kube-system
...
# we should see cluster name and traefik Running status
ingress-traefik-lk85w                   1/1       Running            0  15h


# get list of deployed services, here we should see our tfaas with port 80
kubectl get svc
...
# we should see hostname and port mapping
tfaas       NodePort    10.254.136.150   <none>        8181:30181/TCP   15h
```

3. create new DNS alias at `https://webservices.web.cern.ch/webservices/`
using our k8s node name which we can obtain via `kubectl get node` command.
Use this name with .cern.ch suffix to create a DNS alias we need, e.g.
`tfaas`. The new DNS alias will be accessible as `<aliasName>.web.cern.ch`

4. check that new service is running, e.g. call `curl http://tfaas.web.cern.ch`


