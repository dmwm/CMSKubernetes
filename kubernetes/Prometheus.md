### How to deploy prometheus to k8s
The full procedure has been described in this blog post [1].
Basically we can deploy prometheus as a microservices and
configure it to monitor our cluster. The adjusted code
can be found in this github repository [2]. Here we provide full steps
how to deploy prometheus:
```
# clone kubernetes-prometheus repository
git clone git@github.com:vkuznet/kubernetes-prometheus.git

# create new monitoring namesapce
kubectl create namespace monitoring

# deploy configuration map and service, the --validate=false flag is needed
# when you work on AFS
kubectl -n monitoring apply -f kubernetes-prometheus/config-map.yaml --validate=false
kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-deployment.yaml --validate=false
kubectl -n monitoring apply -f kubernetes-prometheus/prometheus-service.yaml --validate=false

# check deployment and pods
kubectl -n monitoring get deployments
kubectl -n monitoring get pods

# find out prometheus pod name
prom=`kubectl -n monitoring get pods | grep prom | awk '{print $1}'`
# we may access prometheus locally as following
kubectl -n monitoring port-forward $prom 8080:9090

# to access prometheus externally (i.e. from outside CERN network) we should do the following
ssh -S none -L 30000:$kubehost:30000 $USER@lxplus.cern.ch

# once done we can wipe out prometheus from our cluster
kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-service.yaml
kubectl -n monitoring delete -f kubernetes-prometheus/prometheus-deployment.yaml
kubectl -n monitoring delete -f kubernetes-prometheus/config-map.yaml
```

Given deployment will allow prometheus to monitor various metrics of our k8s
cluster, such as CPU, RAM, network usage, health of pods, services, etc.

In order for prometheus to monitor application metrics we'll need to expose
them in our application and then write data-exporter for prometheus.io
An example of such exporter for WMArchive data-service can be found here [3].

Further improvements can be done by extending prometheus to
kibana/grafana dashboard. Full solution is shown here [4].

[1] https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/
[2] https://github.com/vkuznet/kubernetes-prometheus
[3] https://gist.github.com/vkuznet/e401f35ec3d6416de75b8ba08834843b
[4] https://github.com/camilb/prometheus-kubernetes
