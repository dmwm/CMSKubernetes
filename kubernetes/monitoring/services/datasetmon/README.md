## Mongo standalone deployment with 1 replica for **test**

Deployment can be done with kustomize:
```
# to default ns
kubectl apply -k .

# to different namespace, for example `mongo` namespace
kubectl create ns mongo
kubectl -n mongo apply -k .
```

References:
- https://phoenixnap.com/kb/kubernetes-mongodb

### Connect to Mongo Compass
```shell
# [DEGRADED]
mongodb://admin:password@cuzunogl-jhpbqba52z6h-node-0:32000
```

### Login to mongo client
```shell
apt-get update
apt-get install nano

# Service name is cmsmon-mongo
# Headless FQDN definition: <StatefulSet name>-<sequence number>.<Service name>.<Namespace name>.svc.cluster.local
mongo --host mongodb-0.mongodb.datasetmon.svc.cluster.local --port 27017 -u admin -p password
show dbs
use rucio
show collections
db.createCollection("datasets")
ctrl-z

# Create a test json
cat test.json
{ "_id" : 1, "dataset" : "test1", "rse" : "FNAL", "size" : 592}
{ "_id" : 2, "dataset" : "test2", "rse" : "CERN", "size" : 800}

# Use mongoimport cli
mongoimport --host mongodb-0.mongodb.datasetmon.svc.cluster.local --port 27017 -u admin -p password \
    --authenticationDatabase admin --db rucio --collection datasets --file test.json --type=json

# "--authenticationDatabase admin" should be used since we're using admin user to connect "rucio" db.

```

### Index Examples
```shell
db.detailed_datasets.createIndex( { "_id": 1, "Type": 1 } )
db.detailed_datasets.createIndex( { "_id": 1, "Dataset": 1 } )
db.detailed_datasets.createIndex( { "_id": 1, "Dataset": 1, "RSE":1 } )
db.detailed_datasets.createIndex( {"Dataset": 1} )
db.detailed_datasets.createIndex( { "Dataset": 1, "RSE":1 } )

db.detailed_datasets.createIndex( 
  { 
    "Type": "text", 
    "Dataset": "text", 
    "RSE": "text", 
    "Tier": "text",
    "C": "text",
    "RseKind": "text",
    "ProdAccts": "text", } 
)

---
db.datasets.createIndex( { "_id": 1, "Dataset": 1 } )
db.datasets.createIndex( { "Dataset": 1 } )
db.datasets.createIndex( { "LastAccess": 1 } )
db.datasets.createIndex( { "Max": 1 } )
db.datasets.createIndex( { "Min": 1 } )
db.datasets.createIndex( { "Avg": 1 } )
db.datasets.createIndex( { "Sum": 1 } )
db.datasets.createIndex( { "RealSize": 1 } )
db.datasets.createIndex( { "TotalFileCnt": 1 } )

db.datasets.createIndex( 
  { 
    "RseType": "text", 
    "Dataset": "text", 
    "RSEs": "text", 
  } 
)

```
