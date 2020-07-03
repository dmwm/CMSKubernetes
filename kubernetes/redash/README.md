### Introduction
[Redash](http://redash.io) is a middleware which allows to
connect and query your data sources, build
dashboards to visualize data and share them with anyone.

This repository contains all relevant redash k8s manifest files
which we obtained using their docker compose deployment procedure.

### Preparation step
The redash deployment is based on docker compose, please see their
[setup repository](https://github.com/getredash/setup).
In k8s we can either use
[translate compose to k8s procedure](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)
or use
[docker stack deploy](https://www.docker.com/blog/simplifying-kubernetes-with-docker-compose-and-friends/)

The generated k8s yaml files may contain passwords, etc. Therefore, we need
to create a new secret yaml file and replace our sensitive info in all
k8s yaml files to use them from secret file, see the following
[document](https://www.digitalocean.com/community/tutorials/how-to-migrate-a-docker-compose-workflow-to-kubernetes)
So, basically we need to replace sensitive value with
```
          valueFrom:
            secretKeyRef:
              name: redash-secret
              key: SOME_PASSWORD
```

### cluster deployment
```
#create a clsuter
openstack coe cluster create --keypair cloud --cluster-template cmsweb-template-preprod-services-20200612 --flavor m2.large redash

# find out our cluster node name
kubectl get node | grep -v master

# use n as proper minion node name and assign labels
kubectl label node $n failure-domain.beta.kubernetes.io/zone=nova --overwrite
kubectl label node $n failure-domain.beta.kubernetes.io/region=cern --overwrite
kubectl label node $n role=ingress --overwrite

# add new alias to landb
openstack server set --property landb-alias=cmsmon-redash--load-0- redash-k7q7uusl4rky-node-0

# create proper namesspaces
kubectl create ns auth
kubectl create ns redash

# create a link to secrets area which we can download from gitlab cms
# monitoring area

# create auth-secrets in auth namespace
kubectl create secret generic auth-secrets --from-file=secrets/redash-auth/config.json --from-file=secrets/redash-auth/hmac --from-file=secrets/redash-auth/tls.crt --from-file=secrets/redash-auth/tls.key --dry-run=client -o yaml | kubectl apply --namespace=auth -f -

# create redash secrets in redash namesapce
# The secret file contains POSTGRES_PASSWORD, REDASH_COOKIE_SECRET,
# REDASH_DATABASE_URL and REDASH_SECRET_KEY key-value pairs
# Please refer to redash setup to understand their values.
kubectl apply -f secrets/redash/redash-secrets.yaml

# deploy storage
kubectl apply -f storage.yaml

# deploy services
kubectl apply -f postgres.yaml
kubectl apply -f redis.yaml
kubectl apply -f server.yaml
kubectl apply -f scheduler.yaml
kubectl apply -f worker.yaml

# configure and deploy auth proxy service
# it relias on auth-secrets in auth namespace. The auth-secrets
# contains config.json, tls.crt, tls.key and hmac files for auth proxy server.
kubectl apply -f auth-proxy-server.yaml

# add ingress
kubectl apply -f ingress.yaml
```


