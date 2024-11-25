### Cluster creation
Add a new node that will be specifically used for `udp-collector` to some cluster
```
openstack coe cluster resize <cluster name> <current number of worker nodes + 1>
```

Taint the new node so that it would only be used for `udp-collector`
```
kubectl taint nodes <node name> udp-server=true:NoSchedule
```

### Service deployment
```
# download secrets from gitlab
git clone https://:@gitlab.cern.ch:8443/cms-monitoring/secrets.git

# create udp secrets
kubectl create secret generic udp-secrets \
    --from-file=secrets/udp/udp_server.json \
    --dry-run -o yaml | kubectl apply -f -

# deploy the service
kubectl apply -f udp-server.yaml
```

### Service testing
You can use `udp_client` to test the service. See more on [github.com/dmwm/udp-collector](https://github.com/dmwm/udp-collector/blob/master/README.md)

### Alias change
When you are sure that the service is working as expected you can change the alias to point to this new node.