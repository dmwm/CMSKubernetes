### CMSWEB Monitoring
This document describe cmsweb monitoring setup on k8s cluster.
We will rely on few components:
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

[1] https://github.com/vkuznet/kubernetes-prometheus
[2] https://github.com/vkuznet/kubernetes-prometheus/blob/master/config-map.yaml
[3] https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb-nginx/monitor-account.yaml
[4] https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb-nginx/monitor-cron.yaml
[5] https://github.com/ryotarai/prometheus-query
[6] https://github.com/dmwm/CMSKubernetes/blob/master/docker/monitor/monitor.sh
