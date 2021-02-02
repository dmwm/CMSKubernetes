### CMS Monitoring HA documentation
This documentation provides all details for High-Availability (HA) mode 
of CMS monitoring infrastructure.

![HA architecture](../../images/CMSMonitoringHA.png)

To achieve HA mode of operation we use the
following infrastructure setup:
- two kubernetes clusters (ultimately running in different CERN zones)
- [promxy](https://github.com/jacksontj/promxy) a prometheus proxy to unify
  access to Prometheus services
- each HA cluster (called `cms-monitoring-ha<N>`) contains the following stack
  of services:
  - [Prometheus](http://prometheus.io/) as a primary service to collect CMS
    metrics
  - [VictoriaMetrics](https://victoriametrics.github.io/) (VM) as backend service
  for Prometheus services
  - [AlertManager](https://www.prometheus.io/docs/alerting/latest/alertmanager/) (AM)
  as a service for Prometheus alerts
  - [httpgo](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/monitoring/services/httpgo.yaml)
  a custom HTTP server to keep AlertManager messages
  - [kube-eagle](https://github.com/cloudworkz/kube-eagle) a prometheus
    exporter which exports various metrics of kubernetes pod resource requests,
    limits and it's actual usages.

The `promxy` provides an unified access to HA clusters and we configure it to
provide access to VM services. Then, the `promxy` service can be used in
Grafana to represent a data-source to our HA cluster.

We use the following port convention:
- 30090 points to 9090 port of Prometheus and exposed as NodePort on k8s
  infrastructure
- 30093 points to 9093 port of AM, it is default AM port
- 30094 points to 9094 port of AM, it is cluster's AM port for gossip protocol
- 30428 points to 8248 port of VM, it is VM HTTP port and it is used by
  Prometheus for `remote_write` section of its configuration to specify where
  to store its metrics (in our setup Prometheus metrics go to VM)
- 30242 points to 4242 port of VM, it is Open TSDB VM port
Please note, the 30XXX-32XXX port range is allowed by k8s to be used as
NodePorts and be accessible outside of k8s cluster. Therefore we use convension
30000+last three digit of service's port number.

### configuration
To properly configure HA mesh we need the following steps:
- configure promxy service on CMS Monitoring cluster
- configure Prometheus, VM and AM services on HA clusters

#### Configure promxy on CMS Monitoring cluster
The promxy service is quite straightforward. Its configuration file
resides in `secrets/promxy/config.yaml` and contains the following bits:

```
promxy:
  server_groups:
    # VM HA1 server
    - static_configs:
        - targets:
          - cms-monitoring-ha1:30428
      labels:
        sg: vm_ha1
      ignore_error: true
    # VM HA2 server
    - static_configs:
        - targets:
          - cms-monitoring-ha2:30428
      labels:
        sg: vm_ha2
```
Here we use two different server group labels `sg: vm_ha1` and `sg: vm_ha2`.
Also, we refer promxy which targets it should use (the service which will
provide the metrics). In our case it is two different VM services located in
our HA clusters.

#### Configuration of services on HA clusters
For HA clusters we should perform the following steps:
- setup proper environment on lxplus-cloud
```
# setup for HA1 cluster
export KUBECONFIG=/afs/cern.ch/user/v/valya/private/cmsweb/k8s_admin_config/config.monit/config.monitoring-vm-ha1
# setup for HA2 cluster
export KUBECONFIG=/afs/cern.ch/user/v/valya/private/cmsweb/k8s_admin_config/config.monit/config.monitoring-vm-ha2
```
- deploy VM in both clusters
```
kubectl apply -f services/ha/victoria-metrics.yaml
```
- deploy AM in both clusters with cluster peer mode (it is defined as an
  additional flag in AM yaml manifest)
```
# in HA1 cluster use alertmanager-ha1.yaml config
kubectl apply -f services/ha/alertmanager-ha1.yaml
# in HA2 cluster use alertmanager-ha2.yaml config
kubectl apply -f services/ha/alertmanager-ha2.yaml
```
- deploy Prometheus in both clusters with proper rules
```
# get list of prometheus rules create appropriate secret for HA1
files=`ls secrets/prometheus/*.json secrets/prometheus/*.rules secrets/prometheus/ha/ha1/prometheus.yaml | awk '{ORS=" "; print "--from-file="$1""}'`
# get list of prometheus rules create appropriate secret for HA2
files=`ls secrets/prometheus/*.json secrets/prometheus/*.rules secrets/prometheus/ha/ha2/prometheus.yaml | awk '{ORS=" "; print "--from-file="$1""}'`

# then recreate prometheus-secrets in each cluster
ns=default
secret=prometheus-secrets
kubectl -n $ns delete secret $secret
kubectl create secret generic $secret $files --dry-run=client -o yaml | kubectl apply --namespace=$ns -f -

# deploy prometheus service
kubectl apply -f services/ha/prometheus.yaml
```
- deploy `services/ha/kube-eagle.yaml` to monitor our HA cluster
- deploy `services/ha/httpgo.yaml` to consume logs from Prometheus

Next, we can deploy CMS specific services, like `cmsmon-int`. To do that we
need the following pieces in place:
```
# create http and alerts namespaces
kubectl create ns http
kubectl create ns alerts

# create robot-secrets
kubectl create secret generic robot-secrets \
    --from-file=/path/certificates/robotcert-cmsmon.pem \
    --from-file=/path/certificates/robotkey-cmsmon.pem \
    --dry-run=client -o yaml | kubectl apply --namespace=alerts -f -

# deploy proxies
./deploy.sh create proxies

# deploy crons
kubectl apply -f crons/proxy-account.yaml
kubectl apply -f crons/cron-proxy.yaml -n alerts

# create alerts secrets
kubectl create secret generic alerts-secrets \
    --from-file=secrets/alerts/token \
    --dry-run=client -o yaml | kubectl apply --namespace=alerts -f -

# deploy ggus/ssub alert services, use ha1 or ha2 accordingly to your cluster choice
kubectl apply -f services/ha/ggus-alerts-ha1.yaml
kubectl apply -f services/ha/ssb-alerts-ha1.yaml

# deploy cmsmon int service
kubectl apply -f services/ha/cmsmon-intelligence.yaml
```

At the end each HA cluster will have the following set of services
in default namespace:
```
kubectl get pods
# example of HA1 cluster pods
NAME                                READY   STATUS    RESTARTS   AGE
alertmanager-8464c9bb5f-665nc       1/1     Running   0          17m
httpgo-688cc578-fghhc               1/1     Running   0          20d
kube-eagle-79c84f6b6d-94zvl         1/1     Running   0          20d
prometheus-54c6b9545d-gknls         1/1     Running   0          8m28s
victoria-metrics-6cbbb74bbb-494h5   1/1     Running   0          20d

# example of HA1 cluster services
kubectl get svc
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
alertmanager       NodePort    10.254.44.243    <none>        9093:30093/TCP,9094:30094/TCP   19m
httpgo             NodePort    10.254.184.66    <none>        8888:30888/TCP                  20d
kube-eagle         ClusterIP   10.254.115.233   <none>        8080/TCP                        20d
kubernetes         ClusterIP   10.254.0.1       <none>        443/TCP                         20d
prometheus         NodePort    10.254.185.99    <none>        9090:30090/TCP                  20d
victoria-metrics   NodePort    10.254.182.246   <none>        8428:30428/TCP,4242:30242/TCP   20d
```
and the following services in alerts namespace:
```
# list of services in alerts namespace
kubeclt get pods -n alerts
NAME                           READY   STATUS    RESTARTS   AGE
ggus-alerts-648f487547-jrfvg   1/1     Running   0          55m
ssb-alerts-848b5f5cdb-8qq8c    1/1     Running   0          55m

# list of all crons
kubectl get cronjobs -A
NAMESPACE   NAME         SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
alerts      cron-proxy   0 0 * * *   False     0        <none>          62m
```

### Availability zones
[CERN Availability Zone](https://clouddocs.web.cern.ch/containers/tutorials/nodegroups.html#availability-zone)
provides nodes allocation in three different CERN zones, zone-a, zone-b and zone-c.
By default cluster is created randomly in specific zone since
openstack will pick a zone oportunistically.
The following rules applies:

1. when a cluster created without Availability Zone (AZ),
openstack will pick a zone oportunistically. Could be any zone.

2. when you create a cluster with `--labels availability_zone=foo`,
all nodes of default master and default worker will be in foo

3. when you create a NG (nodegroups) with AZ (eg zone-a), 
all NG nodes will be in the specific az, new NG nodes too.

4. combine 1 and 3. cluster resize will create a node in any AZ.
NG resize will create node to the specified zone, (eg zoneA)

5. when creating a NG without an AZ, same as 1.

Here is examples of few commands operator can use either to find
AZ of k8s nodes, or create nodegroup (NG) for k8s nodes in specific zone:

```
# find AZ for a given VM
openstack server show "<vm name or id>"

# tfind AZ for a given k8s node
kubectl describe node

# for example
kubectl describe node monitoring-vm-ha1-3k4ljllzgy5x-node-0 | grep zone
                    failure-domain.beta.kubernetes.io/zone=cern-geneva-c
                    topology.cinder.csi.openstack.org/zone=cern-geneva-c
                    topology.kubernetes.io/zone=cern-geneva-c
# the first entry comes from master, while another from minion nodes

# create a node group in specific zone, here we put ha1 cluster
# in zone-a and ha2 cluster in zone-b
openstack coe nodegroup create monitoring-vm-ha1 zone-a --labels availability_zone=cern-geneva-a
openstack coe nodegroup create monitoring-vm-ha2 zone-b --labels availability_zone=cern-geneva-b
```

### References

- [High-Availability for Prometheus and AlertManager](https://www.robustperception.io/high-availability-prometheus-alerting-and-notification)
- [CERN Availability Zones](https://clouddocs.web.cern.ch/containers/tutorials/nodegroups.html#availability-zone)
