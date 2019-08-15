##### Special node about nginx ingress controller.
we may need to adjust nginx controller of the cluster to avoid its crashes until
it is fixed by CERN IT, this can be done by editing its confiugration
one time operation:
- remove xxxxxxxProbe section (healthz)
- increase ram allocation from 64Mi to 128Mi (or more, e.g. 256Mi)
It is one time operation once you have working cluster and should be
done as following
```
# edit nginx ingress controller spec
kubectl -n kube-system edit daemonset.apps/nginx-ingress-controller

# then we can restart the daemon set as following, e.g.
kubectl -n kube-system delete pod nginx-ingress-controller-gsw2b
# or better use this independent from pod name command
kubectl -n kube-system get pods | grep ingress-controller | awk '{print "kubectl -n kube-system delete pod "$1""}'

```

##### Deployment of nginx ingress controller
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
