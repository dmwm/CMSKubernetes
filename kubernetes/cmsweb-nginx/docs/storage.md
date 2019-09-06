### Adding additional storage volumes to k8s
We can create an additional volume, e.g. to store our cmsweb logs or use
crabcache data volume, via the following command:
```
# setup proper project name
export OS_PROJECT_NAME="CMS Web"

# create new storage volume of 2000GB with name crabcache
openstack volume create crabcache --size 2000
openstack volume list

# now you can mount this data folume into k8s pod by using the following configuration
# you should replace volumeID with proper ID which can be found from
# openstack volume list command
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  labels:
    app: crabcache
  name: crabcache
spec:
  selector:
    matchLabels:
      app: crabcache
  template:
    metadata:
      labels:
        app: crabcache
    spec:
      containers:
      - image: cmssw/crabcache
        name: crabcache
        volumeMounts:
        ....
        - name: crabcache
          mountPath: /crabcache
      volumes:
      ....
      - name: crabcache
        cinder:
            volumeID: 2e91281d-749d-43f2-8222-989e1c7d37a2
            fsType: ext4
```

### Using PersistentVolumeClaim's
Even though the above method works it only works with a single pod. To have
persistent storage volume available in all replicas (multiple pods) you
should use Persistent Volume Claim (PVC) method. First, create an
appropriate storage configuration, e.g.
```
# verify which storage class is available for you via
openstack quota show  | grep gigabytes
# in my case I had storage volume with cpio1 class
gigabytes_cpio1 | 102400

# then create storage file with cpio1 class name (change to whatever available
# in your case):
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: cpio1
provisioner: kubernetes.io/cinder
parameters:
  type: cpio1
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: crabcache-claim
  annotations:
    volume.beta.kubernetes.io/storage-class: cpio1
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2000Gi # pass here the size of the volume
... # here we may add another PVC section
```
We save above content into `cinder-storage.yaml` file. It describe
storage class we'll use and PVC's for our needs. In particular,
we created crabcache-claim PVC with 2TB of storage.

Please inspect your PV/PVC's to get proper labels and ensure
that those labels are applied to your minions.
```
Check PV's and PVC's
kubectl get pvc
kubectl get pv
# then find out details of specific PVC
kubectl describe pv pvc-de11281d-cffd-11e9-a480-fa163ea275e0
# and check which labels have been applied, e.g.
    failure-domain.beta.kubernetes.io/region=cern
    failure-domain.beta.kubernetes.io/zone=nova
# make sure that these labels are applied to your minions
kubectl label node <node-minion> failure-domain.beta.kubernetes.io/zone=nova --overwrite
```
Now you can use your PVC's in your deployment, e.g. see
[crabcache](services/crabcache.yaml) and [dqmgui](services/dqmgui.yaml)
configuration.

**NOTE**: if you want to autoscale pods which use PVC you can only have
multiple replicas on a node where PVC will be attached. To do that, we
should create a new label for specific minion which will have attached 
PV storage.
```
# mark minion-5 with label=value appropriate for couchdb storage
kubectl label node cmsweb-services2-km2ftghb3es5-minion-5 storage=couchdb
# use nodeSelector in couchdb yaml file to choose this minion
  nodeSelector:
      storage: couchdb
# and then we can scale couchdb like
kubectl autoscale deployment crabcache --cpu-percent=80 --min=2 --max=3
```
Using this recipe will create 2 pods for couchdb on the same minion which will
have attached PV storage.

### Creating storage areas on CEPHFS
**NOTE**: this method was note tested in cmsweb setup and we listed
here only for completeness.

If you want to creage cephfs storage volume you need to follow this
recipe:
```
# create new cephfs storage
kubectl apply -f storage-cephfs.yaml
# check its quota
kubectl get pvc

# delete storage
kubectl delete -f storage-cephfs.yaml
manila list
manila delete <ID>
kubectl delete pv --all

# check if resources are freed
kubectl get pvc
manila list
```

### References
1. [clouddocs](http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/cinder.html)
2. [assign pods to nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
