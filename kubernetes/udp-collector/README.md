### Cluster creation
Create new cluster with new template
```
./create_template.sh udp-cluster
openstack coe cluster create --keypair cloud --cluster-template udp-server-template udp-cluster
```

### Service deployment
```
# download secrets from gitlab
git clone https://:@gitlab.cern.ch:8443/cms-monitoring/secrets.git

# create udp secrets
kubectl create secret generic udp-secrets \
    --from-file=secrets/udp/udp_server.json \
    --dry-run -o yaml | kubectl apply -f -

# deploy the service
kubectl apply -f udp-server.yaml

# add ingress controller
kubectl apply -f ingress.yaml

# label our nodes
kubectl label node <minion-node> role=ingress --overwrite

```

### Adjusting NGINX ingress controller
We need to adjust nginx ingress controller to expose port 9331 which is used
by our service. The helm based procedure can be found
[here](https://clouddocs.web.cern.ch/containers/tutorials/lb.html#expose-tcp-ports-with-ingress)
Here we only outline steps required here:
```
$ export HELM_HOME="${HOME}/ws/helm_home"
$ export HELM_TLS_ENABLE="true"
$ export TILLER_NAMESPACE="magnum-tiller"
$ helm get values nginx-ingress > values.yaml
$ vim values.yaml # add the UDP ports you want in the udp section

# here is an example of tpc/udp parts in values.yaml file
tcp:
  #<ingress-port>: "<namespace>/<server-name>:<service-port>"
udp:
  9331: "default/udp-server:9331"

$ helm upgrade nginx-ingress stable/nginx-ingress --namespace=kube-system -f values.yaml --recreate-pods
```

We also would like to disable standard ports 80 and 443 in our cluster to
better comply with CERN security scan. To do that we need to add the following
changes to values.yaml
```
controller:
  containerPort: null
...
#   hostNetwork: true
  hostNetwork: false
...
defaultBackend:
  affinity: {}
#   enabled: true
  enabled: false
```


There is another way to do this via nginx configuration,
please refer to this
[documentation](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)

For traefik ingress controller the ports can be adjusted
via the following
[procedure](https://docs.traefik.io/routing/providers/kubernetes-crd/#kind-ingressroutetcp).
Please note, that it requires 2.x version of traefik middleware. So far
CERN IT only supports version 1.x
