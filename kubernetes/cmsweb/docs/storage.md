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

### steps to create production shares for log partitions
```
grep namespace storages/cephfs-storage-logs.yaml  | \
awk '{print "manila create --share-type \"Meyrin CephFS\" --name "$2"-share cephfs 100"}' | /bin/sh

# if necessary we may need to obtain a token and then use it with all manila commands
MANILA_URL=`openstack catalog show manilav2 | grep public | awk '{print $4}'`
USER_TOKEN=`openstack token issue | grep "| id" | awk '{print $4}'`
# use token and manila url with manila command
manila --os-token=$USER_TOKEN --bypass-url=$MANILA_URL list

# OR, we better to cofigure our shell to use openstack, see
# https://clouddocs.web.cern.ch/tutorial/create_your_openstack_profile.html
# by downloading and sourcing this configuration
# https://openstack.cern.ch/project/api_access/openrc/
# source CMSWeb-openrc.sh
# then we can proceed with manila commands

manila list
+--------------------------------------+------------------------------------------+------+-------------+-----------+-----------+-----------------------+------+-------------------+
| ID                                   | Name                                     | Size | Share Proto | Status    | Is Public | Share Type Name       | Host | Availability Zone |
+--------------------------------------+------------------------------------------+------+-------------+-----------+-----------+-----------------------+------+-------------------+
| 8b919fa0-1bd8-4679-b225-eabab8bae0e7 | tzero-share                              | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| b9502086-f115-42b6-bfc9-e84373bdeb2e | phedex-share                             | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| 18b71caa-0a59-4b97-8894-4ec33a7da9aa | dmwm-share                               | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| 41f54df1-d654-47bb-bd79-b5549a58863f | dqm-share                                | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| 5169d4a8-54b0-4cb7-97f9-43cf37717fc6 | dbs-share                                | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| 0610d8d7-b86e-46f4-a8ce-6aa373e24e0c | das-share                                | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| 2f2535db-4b76-4ff7-badf-b255c8c93ac6 | crab-share                               | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| daebb9d9-ad68-47f2-bafb-10cceaa085f1 | couchdb-share                            | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| c1aeed05-29ad-4320-8885-a634d2c5354f | confdb-share                             | 100  | CEPHFS      | available | False     | Meyrin CephFS         |      | nova              |
| 190d1a4a-66ff-49cc-ae75-7beb6656748d | pvc-ee9dc68f-e449-11e9-901a-fa163ea275e0 | 108  | CEPHFS      | available | False     | Geneva CephFS Testing |      | nova              |
+--------------------------------------+------------------------------------------+------+-------------+-----------+-----------+-----------------------+------+-------------------+

# then we can load our shares to k8s
kubectl apply -f storages/cephfs-storages-logs.yaml --validate=false
...
# next you can change your service file to use this shares, e.g.
cat services/das.yaml | sed -e "s,#PROD#,      ,g" | \
   kubectl apply --validate=false -f -

# grant access to our share
manila access-allow confdb-share cephx cmsweb-auth
manila access-allow couchdb-share cephx cmsweb-auth
manila access-allow crab-share cephx cmsweb-auth
manila access-allow das-share cephx cmsweb-auth
manila access-allow dbs-share cephx cmsweb-auth
manila access-allow dqm-share cephx cmsweb-auth
manila access-allow dmwm-share cephx cmsweb-auth
manila access-allow phedex-share cephx cmsweb-auth
manila access-allow tzero-share cephx cmsweb-auth

manila access-list das-share
+--------------------------------------+-------------+-------------+--------------+--------+------------------------------------------+----------------------------+----------------------------+
| id                                   | access_type | access_to   | access_level | state  | access_key                               | created_at                 | updated_at                 |
+--------------------------------------+-------------+-------------+--------------+--------+------------------------------------------+----------------------------+----------------------------+
| 5d64969b-8adf-42ae-b0dd-19b77e96f02d | cephx       | cmsweb-auth | rw           | active | AQCsy6VdPyOYKhAAf8vVPWbTxr/irNllIpdr4w== | 2019-10-15T13:37:48.000000 | 2019-10-15T13:37:49.000000 |
+--------------------------------------+-------------+-------------+--------------+--------+------------------------------------------+----------------------------+----------------------------+
manila access-list confdb-share
+--------------------------------------+-------------+-------------+--------------+--------+------------------------------------------+----------------------------+----------------------------+
| id                                   | access_type | access_to   | access_level | state  | access_key                               | created_at                 | updated_at                 |
+--------------------------------------+-------------+-------------+--------------+--------+------------------------------------------+----------------------------+----------------------------+
| b52c24ed-a645-48c0-8025-a549f8ef9cbb | cephx       | cmsweb-auth | rw           | active | AQCsy6VdPyOYKhAAf8vVPWbTxr/irNllIpdr4w== | 2019-10-15T13:44:12.000000 | 2019-10-15T13:44:13.000000 |
+--------------------------------------+-------------+-------------+--------------+--------+------------------------------------------+----------------------------+----------------------------+

manila share-export-location-list das-share
+--------------------------------------+---------------------------------------------------------------------------------------------------------------------+-----------+
| ID                                   | Path                                                                                                                | Preferred |
+--------------------------------------+---------------------------------------------------------------------------------------------------------------------+-----------+
| 2da1f748-8d80-4bdc-ad33-9fd0f620c6d0 | 137.138.121.135:6789,188.184.85.133:6789,188.184.91.157:6789:/volumes/_nogroup/748b1f6c-7617-4b97-a49a-e9c3fae787b9 | False     |
+--------------------------------------+---------------------------------------------------------------------------------------------------------------------+-----------+
```

### References
1. [clouddocs](http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/cinder.html)
2. [CephFS shares](https://clouddocs.web.cern.ch/containers/tutorials/cephfs.html#existing-cephfs-share)
3. [access CephFS shares](https://clouddocs.web.cern.ch/file_shares/quickstart.html)
4. [manila access](https://clouddocs.web.cern.ch/file_shares/programmatic_access.html)
5. [assign pods to nodes](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
6. [manila references](https://docs.openstack.org/manila/pike/cli/manila.html)
