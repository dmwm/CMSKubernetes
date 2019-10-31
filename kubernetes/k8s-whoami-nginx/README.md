### cluster deployment
The vk-k8s-test service will be deployed on k8s cluster using `veknet/httpgo`
container. This container is build using the
[httpgo](https://github.com/dmwm/CMSKubernetes/tree/master/docker/httpgo)
Go code. The later is a simple HTTP web-service which responses to
incoming request with Hello world message and prints out all requests
headers.

To create vk-k8s-test app on kubernetes cluster please follow these steps:

1. create new cluster by login to `lxplus-cloud.cern.ch` and execute the
   following command

```
# please make cluster with appropriate template
# the template should contains nginx ingress controller at least
# please refer to
# https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb-nginx/scripts/create_templates.sh
# how to create an appropriate template
openstack coe cluster create test-cluster --keypair cloud --cluster-template <tmpl-name>
```

You will need to wait once cluster is created. You may verify its existence
with this command:
```
openstack coe cluster list
# it should have CREATE_COMPLETE status
```

Once cluster is created we need to perform one-time operation to get pem files
and config for it. Just do:
```
$(openstack coe cluster config test-cluster)
```

Then go to `https://webservices.web.cern.ch/webservices/` and register new
domain name, e.g. vk-k8s-test, for cluster node we got. We can get cluster node via
the following command:
`
kubectl get node
`

The next series of steps is required until CERN IT will deploy new flag for
ingress nginx controller
```
# create a new domain alias for your cluster on
# https://webservices.web.cern.ch/webservices/Services/RegisterExternalSite/Default.aspx
# or use this command (replace landb-alias and minion names)
# this command didn't work for me but was listed in CERN IT instructions
openstack server set --property landb-alias=vk-k8s-test test-cluster-sds42p2lfiup-minion-0
```

Once you register your domain name, you may obtain host certificates
by visiting [ca.cern.ch](https://ca.cern.ch/ca/) and click on
**New CERN Host certificate** link. In this form please use your
domain name (in this example I used vk-k8s-test.web.cern.ch)
and obtain your host certificate (it will be issued as `vk-k8s-test.web.p12`
or more generically as `your_host_name.p12`). Then you should convert p12
file into pem format as following:
```
# here I used my p12 file and choose my names for pem files
openssl pkcs12 -in vk-k8s-test.web.p12 -clcerts -nokeys -out vk-k8s-test-hostcert.pem
openssl pkcs12 -in vk-k8s-test.web.p12 -nocerts -nodes -out vk-k8s-test-hostkey.pem
```

Once you obtain your pem host certificates files you may use them
in your cluster, e.g. let's create a ing-secrets file with them:
```
# for ingress we must use tls.key and tls.crt file names
ln -s vk-k8s-test-hostcert.pem tls.crt
ln -s vk-k8s-test-hostkey.pem tls.key
kubectl create secret generic ing-secrets --from-file=tls.key --from-file=tls.crt --dry-run -o yaml | kubectl apply --validate=false -f -
```


2. Now, we can deploy our k8s using the following commands:
```
# create new secret file for httpsgo service
kubectl create secret generic httpsgo-secrets --from-file=httpsgoconfig.json --dry-run -o yaml | kubectl apply --validate=false -f -

# deploy httpgo service
kubelct apply -f httpgo.yaml --validate=false

# deploy httpsgo service
kubelct apply -f httpsgo.yaml --validate=false

# we need to label our node with ingress role that ingress controller
# will be enabled (here replace your minion name)
kubectl label node test-cluster-5tgnixyeazor-minion-0 role=ingress --overwrite

# deploy ingress controller
kubectl apply -f ing-nginx.yaml --validate=false
```

3. check that new service is running, e.g. 
```
# issue curl command with your certificates
curl -L -k --key ~/.globus/userkey.pem --cert ~/.globus/usercert.pem http://vk-k8s-test.web.cern.ch
# it should print something like this
Header field "User-Agent", Value ["curl/7.29.0"]
Header field "Accept", Value ["*/*"]
Host = "vk-k8s-test.web.cern.ch"
RemoteAddr= "10.100.22.1:48688"


Finding value of "Accept" ["*/*"]
* Connection #0 to host vk-k8s-test.web.cern.ch left intact
Hello Go TLS world!!!
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
