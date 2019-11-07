### CMS NATS
The [NATS](https://nats.io/) is secure and high performance open source
messaging system for distributed (cloud native) application written in Go.
It is similar to [Kafka](https://kafka.apache.org/), a
distributed streaming platform, written in Scala, Java.

### CMS NATS deployment to k8s
The deployment of CMS NATS to k8s cluster is trivial. Please follow
these steps:
```
# create a cluster
create_nats.sh <ssh key-pair> <cluster name>
# deploy NATS server
deploy_nats.sh
```

That's it! If you want to connect `nats-top` tool to your running
cluster please use these commands:

```
kubectl run -i --rm --tty nats-box --image=synadia/nats-box:latest --restart=Never
nats-top -s nats-cluster-mgmt
```
