### CMS Monitoring HA documentation
This documentation provides all details for High-Availability (HA) mode 
of CMS monitoring infrastructure. The architecture of this mode
is represented below:
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
- 30093 points to 9093 port of AM
- 30428 points to 8248 port of VM
- 30242 points to 4242 port of VM
Please note, the 30XXX-32XXX port range is allowed by k8s to be used as
NodePorts and be accessible outside of k8s cluster. Therefore we use convension
30000+last three digit of service's port number.
