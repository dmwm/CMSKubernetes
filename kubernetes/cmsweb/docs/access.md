### Cluster access rules
We can create specific cluster rules following this
[procedure](http://clouddocs.web.cern.ch/clouddocs/containers/tutorials/kubernetes-keystone-authentication.html)
For example, we'll create `edit` roles for user `user` to access our default
cluster namespace:

```
# create config area (admins) for end-users
openstack coe cluster config <cluster name> --dir admins

# create config area (userss) for end-users using keystone
openstack coe cluster config <cluster name> --use-keystone --dir users

# setup appropriate config
export KUBECONFIG=users/config

# create new rolebinding with edit role for given <user>
kubectl create rolebinding <user>-edit --clusterrole=edit --user <user> --namespace=default

# create new rolebinding with view role for given <user>
kubectl create rolebinding <user>-view --clusterrole=view --user <user> --namespace=default

# delete rolebinding
kubectl delete rolebinding user-edit
kubectl delete rolebinding user-view

# list existing rolebindings
kubectl get rolebinding
```
