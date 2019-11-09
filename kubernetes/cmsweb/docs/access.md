### Cluster access rules
We can create specific cluster rules following this
[procedure](http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/kubernetes-keystone-authentication.html)
For example, we'll create `edit` roles for user `user` to access our default
cluster namespace:

```
# create config area for end-users
openstack coe cluster config <cluster name> --dir admin-creds
# create config area for end-users using keystone
openstack coe cluster config <cluster name> --use-keystone --dir user-creds

# setup appropriate config
export KUBECONFIG=user-creds

# create new rolebinding with edit role for given user
kubectl create rolebinding user-edit --clusterrole=edit --user user --namespace=default
# delete rolebinding
kubectl delete rolebinding user-edit
# list existing rolebindings
kubectl get rolebinding
```
