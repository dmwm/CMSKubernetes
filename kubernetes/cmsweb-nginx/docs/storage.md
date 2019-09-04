### Adding additional storage volumes to k8s
We can also create an additional volume, e.g. to store our cmsweb logs, via the
following command:
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

And, if you want to creage cephfs storage volume you need to follow this
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
