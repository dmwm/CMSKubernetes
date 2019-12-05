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
