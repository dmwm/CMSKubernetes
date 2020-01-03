### cmsweb k8s monitoring
This directory contains all files used in cmsweb k8s cluster for monitoring
purposes. They represent the following categories:
- prometheus.yaml for Prometheus service collecting various cmsweb services
  metrics exposed by their exporters
- logstash.yaml for Logstash service collecting logs coming from filebeats
  deployed on cmsweb services
- monitor-cron.yaml and monitor-account.yaml for running monitoring script
  to collect specific service metrics and scale up/down services based
  on these metrics
- service specifics monitoring scripts like mon-frontend.yaml,
  mon-dbs-global-r.yaml which run under monitor-account and collects
  metrics from prometheus server and scale up/down appropriate services

### CMSWEB Monitoring
We rely on few components:
- setup prometheus service [1] with appropriate changes to its config map to
  point to k8s exporters end-points/ports, for particular example
  please see [2].
- setup monitoring cronjob account [3]
- setup monitoring cronjob [4] with custom image to perform the following actions
  - query prometheus server either via curl or prometheus-query [4]
  - invoke kubectl scale
  both of these actions are implemented in monitor.sh script, see [6]

At the end we setup a cronjob which calls monitor.sh script. This script
check given metric in prometheus service and either scale up or down
appropriate data-service.

### cmsweb k8s monitoring
The cluster monitoring is done via kube-eagle [7]. For that we deploy
metrics-server [8] and then kube-eagle. The later provides metrics for
Prometheus server. Then we observe these metrics in Prometheus and
plot them in Grafana, see kube-eagle [7] for details.

#### References
1. https://github.com/vkuznet/kubernetes-prometheus
2. https://github.com/vkuznet/kubernetes-prometheus/blob/master/config-map.yaml
3. https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/monitor-account.yaml
4. https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/monitor-cron.yaml
5. https://github.com/ryotarai/prometheus-query
6. https://github.com/dmwm/CMSKubernetes/blob/master/docker/monitor/monitor.s
7. https://github.com/cloudworkz/kube-eagle
8. https://github.com/kubernetes-sigs/metrics-server
