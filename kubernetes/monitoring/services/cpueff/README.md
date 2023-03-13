# CPU Efficiency Web Service

References:

- https://phoenixnap.com/kb/kubernetes-mongodb

### Test utils

```
# Change ClusterIP to NodePort for test and set 32017 as node port

# Connect to Mongo Compass url
mongodb://admin:password@[CLUSTER-NAME]-xxxxx-node-0:32017
```

### Login to mongo client

```shell
apt-get update
apt-get install nano

# Service name is cmsmon-mongo
# Headless FQDN definition: <StatefulSet name>-<sequence number>.<Service name>.<Namespace name>.svc.cluster.local
mongo --host mongodb-0.mongodb.cpueff.svc.cluster.local --port 27017 -u admin -p password
show dbs
use cpueff
show collections

# Use mongoimport cli
mongoimport --host mongodb-0.mongodb.cpueff.svc.cluster.local --port 27017 -u admin -p password \
    --authenticationDatabase admin --db cpueff --collection sc_task --file test.json --type=json
```
