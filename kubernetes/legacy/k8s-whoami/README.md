### k8s-whoami cluster deployment
The k8s-whoami service will be deployed on k8s cluster using `veknet/httpgo`
container. This container is build using the
[httpgo](https://github.com/dmwm/CMSKubernetes/tree/master/docker/httpgo)
Go code. The later is a simple HTTP web-service which responses to
incoming request with Hello world message and prints out all requests
headers.

To create k8s-whoami app on kubernetes cluster please follow these steps:

1. create new cluster by login to `lxplus-cloud.cern.ch` and execute the
   following command

```
openstack --os-project-name "CMS Webtools Mig" coe cluster create k8s-whoami --keypair cloud --cluster-template kubernetes-1.13.3-1 --labels cern_enabled=True,kube_tag=v1.13.3-12,kube_csi_enabled=True,kube_csi_version=v0.3.2,container_infra_prefix=gitlab-registry.cern.ch/cloud/atomic-system-containers/,cvmfs_tag=qa,ceph_csi_enabled=True,flannel_backend=vxlan,ingress_controller=traefik
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
$(openstack --os-project-name "CMS Webtools Mig" coe cluster config k8s-whoami)
```

Then go to `https://webservices.web.cern.ch/webservices/` and register new
domain name, e.g. k8s-whoami, for cluster node we got. We can get cluster node via
the following command:
`
kubectl get node
`

2. Now, we can deploy our k8s app using `deploy.sh` script. You may verify apps
   creation by using these commands:
```
# get list of pods (deployed apps) in default namespace
# here we should get k8s-whoami app deployed
kubectl get pods
...
# we should see cluster name and Running status
k8s-whoami-5556f46d6c-phkmq   1/1       Running   0          15h

# get list of pods in kube-system namespace, here we should see traefik controller
kubectl get pods -n kube-system
...
# we should see cluster name and traefik Running status
ingress-traefik-lk85w                   1/1       Running            0  15h


# get list of deployed services, here we should see our k8s-whoami with port 80
kubectl get svc
...
# we should see hostname and port mapping
httpgo       ClusterIP   10.254.40.241   <none>        8888/TCP   40m
```

3. create new DNS alias at `https://webservices.web.cern.ch/webservices/`
using our k8s node name which we can obtain via `kubectl get node` command.
Use this name with .cern.ch suffix to create a DNS alias we need, e.g.
`k8s-whoami`. The new DNS alias will be accessible as `<aliasName>.web.cern.ch`

4. check that new service is running, e.g. 
```
# issue curl command with your certificates
curl -L -k --key ~/.globus/userkey.pem --cert ~/.globus/usercert.pem http://k8s-whoami.web.cern.ch
# it should print something like this
GET / HTTP/1.1
Header field "X-Forwarded-Proto", Value ["https"]
Header field "X-Forwarded-Server", Value ["k8s-whoami-sds42p2lfiup-minion-0.cern.ch"]
Header field "X-Real-Ip", Value ["188.184.108.51"]
Header field "Accept", Value ["*/*"]
Header field "X-Forwarded-Port", Value ["443"]
Header field "X-Forwarded-Tls-Client-Cert", Value ["..."]
Header field "X-Real-Ip", Value ["188.184.108.51"]
Header field "Accept-Encoding", Value ["gzip"]
Header field "User-Agent", Value ["curl/7.29.0"]
Header field "Accept", Value ["*/*"]
Header field "X-Forwarded-Host", Value ["k8s-whoami.web.cern.ch"]
Header field "X-Forwarded-Tls-Client-Cert", Value ["..."]
Host = "k8s-whoami.web.cern.ch"
RemoteAddr= "10.100.22.1:39198"


Finding value of "Accept" ["*/*"]Hello Go world!!!
```

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
