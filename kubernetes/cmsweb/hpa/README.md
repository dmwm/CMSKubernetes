This area defines hpa (Horizontal Pod Autoscaler) for cmsweb services.
In short we need two pieces:
- definition of prometheus rules to be used for hpa, see
[prometheus-adapter.yml](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/monitoring/prometheus/adapter/prometheus_adapter.yml)
- the hpa manifest files (this area)

For full documentation please refer to this
[guide](https://github.com/Cloud-PG/prometheus-hpa/tree/master)
