### Service mesh
The Service mesh describes the network of microservices that make up such
applications and the interactions between them. The Service mesh is provided
by [istio](https://istio.io/docs) middleware. In particular, it provides
- automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic
- fine-grained control of traffic behavior with rich routing rules, retries,
failovers, and fault injection
- a pluggable policy layer and configuration API supporting access controls, rate
limits and quotas
- automatic metrics, logs, and traces for all traffic within a cluster, including
cluster ingress and egress
- secure service-to-service communication in a cluster with strong identity-based
authentication and authorization

##### Installation instructions
In order to setup and use Service mesh please follow up
[istio installation guide](https://istio.io/docs/setup/getting-started/)
and install it as production environment, see custom
installation [guide](https://istio.io/docs/setup/install/istioctl/).
Here we briefly summarize all steps in one section:
```
mkdir tmp
cd tmp
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.4.3
export PATH=$PWD/bin:$PATH
istioctl manifest apply
istioctl manifest generate > profile.yaml
istioctl verify-install -f profile.yaml
kubectl get svc -n istio-system
kubectl get pods -n istio-system
```

##### Installation of (micro-)services
To install list of micro-services we will use `dev` namespace
and `httpgo` application. Please follow these steps:

```
# create new namespace for deployment
k create namespace dev
# enable istio injection in dev namespace
k label namespace dev istio-injection=enabled

# Deploy our service
k apply -f httpgo.yaml

# deploy gateway
k apply -f httpgo-gateway.yaml

# check status of gateway
k -n dev get gateway

# deploy virtual services
k apply -f httpgo-virtual-service.yaml

# check status of virtual service
k -n dev get virtualservice

# deploy destination rules
k apply -f httpgo-destinations.yaml

# check destination rules
k get destinationrules --all-namespaces
```

### Ingress Gateway
For full explanation see this
[document](https://istio.io/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports). Here we present short set of commands
```
# determine ingress IP and ports
k get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                                                                                                      AGE
istio-ingressgateway   LoadBalancer   10.254.135.79   <pending>     15020:32408/TCP,80:32492/TCP,443:30348/TCP,15029:31022/TCP,15030:31911/TCP,15031:30004/TCP,15032:30552/TCP,15443:30636/TCP   42h

# since our ingress gateway does not have external IP
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```
To test access to your service you may use simple curl command, e.g.
```
curl http://${GATEWAY_URL}/httpgo
```
