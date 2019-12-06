### CMS Promeetheus service
The [Prometheus](https://prometheus.io/) is  an open-source systems monitoring.

### CMS Prometheus deployment to k8s
We rely on [Prometheus-Opeartor](https://github.com/coreos/prometheus-operator)
CRD which can be used to easily deploy prometheus service on k8s
infrastructure.

The deployment of CMS Prometheus to k8s cluster is trivial. Please follow
these steps:
```
# login to lxplus-cloud
ssh lxplus-cloud

# create a cluster
create_cluster.sh <ssh key-pair> <cluster name>
# or you can use manual procedure, e.g.
openstack coe cluster create --keypair cloud \
    --cluster-template kubernetes-1.15.3-3 \
    --flavor m2.medium --master-flavor m2.medium --node-count 2 prometheus-cluster


# deploy Prometheus server, the deployment scripts expects
# that your area contains prometheus-config.yaml configuration file
deploy.sh
```

That's it! You can see the status of your deployment as following:
```
kubectl get pods
NAME                                      READY   STATUS    RESTARTS   AGE
prometheus-operator-6685db5c6-2rz54       1/1     Running   0          30h
prometheus-prometheus-0                   3/3     Running   1          4h31m
prometheus-prometheus-1                   3/3     Running   1          4h31m
pushgateway-deployment-5496f6b68d-4ph4q   1/1     Running   0          5h28m

# and you can login to your prometheus pod as following
kubectl exec -ti prometheus-prometheus-0 -c prometheus sh
```

### VictoriaManifest backend
We also deploy [VictoriaMetrics](https://victoriametrics.com/) service
which can be used as Prometheus backend and long-term storage, as well
as a storage for NATS monitoring messages. It supports Prometheus
[PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/),
[Prometheus Query API](https://prometheus.io/docs/prometheus/latest/querying/api/),
and additional
[extensions](https://github.com/VictoriaMetrics/VictoriaMetrics/wiki/ExtendedPromQL)
which we can use for monitoring purposes. The VictoriaMetrics
provides high-performance, scalability, queyring, high data-compression,
and efficient storage, for all details please refer
to [VictoriMetrics documentation](https://victoriametrics.github.io/#pure-go-build-cgo_enabled0).

The deployment is done internally by `deploy.sh` or can be done
as simple as following:
```
kubectl apply -f victoria-metrics.yaml
```
and we can insert and query data as following:
```
url="http://cms-prometheus.cern.ch"
purl=${url}:30422/api/put
rurl=${url}:30428/api/v1/export

# insert data into VictoriaMetrics
echo "put data into $purl"
curl -H 'Content-Type: application/json' -d '{"metric":"cms.dbs.exitCode", "value":8021, "tags":{"site":"T2_US", "task":"test", "log":"/path/file.log"}}' "$purl"

# query data from VictoriaMetrics
echo "get data from $rurl"
curl -G "$rurl" -d 'match[]=cms.dbs.exitCode'

# the output of query
put data into http://cms-prometheus.cern.ch:30422/api/put
get data from http://cms-prometheus.cern.ch:30428/api/v1/export
{"metric":{"__name__":"cms.dbs.exitCode","log":"/path/file.log","site":"T2_US","task":"test"},"values":[8021,8021],"timestamps":[1575635036000,1575635041000]}
```

