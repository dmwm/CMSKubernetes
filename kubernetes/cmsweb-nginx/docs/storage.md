### Adding additional storage volumes to k8s
We can also create an additional volume, e.g. to store our cmsweb logs, via the
following command:
```
openstack --os-project-name "CMS Webtools Mig" volume create cmsweb_logs --size 50
openstack --os-project-name "CMS Webtools Mig" volume list

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
