### How to access openstack from Docker image

```
# login to node with docker client/server
# obtain valid kerberos ticket
kinit

# run docker ciadm image
docker run -it --privileged -e KRB5CCNAME=$KRB5CCNAME -v /tmp:/tmp gitlab-registry.cern.ch/cloud/ciadm:queens

# setup proper environemnt
export OS_AUTH_URL=https://keystone.cern.ch/krb/v3
export OS_AUTH_TYPE=v3kerberos
export OS_USERNAME=valya
export OS_IDENTITY_API_VERSION=3
export OS_PROJECT_DOMAIN_ID=default
export OS_PROJECT_NAME="Personal valya"
export OS_MUTUAL_AUTH=disabled

# find out our cluster
openstack coe cluster list

# create configuration
openstack coe cluster config vkcluster

# export KUBECONFIG

# run kubectl commands
kubectl get node
```
