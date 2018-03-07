Here we present simple list of instructions/commands to build, run and upload
dbs2go docker image. Please replace `USERNAME` with appropriate user name
of your docker account.

```
### build image
docker build -t USERNAME/dbs2go .

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image, here we map local /tmp/dbs2go area to /etc/secrets in container for app to use
### in this area we can store dbs-proxy as well as dbfile, server.{crt,key}
docker run --rm -h `hostname -f` -v /tmp/dbs2go:/etc/secrets -i -t veknet/dbs2go /bin/bash
### within a container app we can query DBS
curl -k --key /etc/secrets/dbs-proxy --cert /etc/secrets/dbs-proxy "https://localhost:8989/dbs/datasets?dataset=/ZMM*/*/*"

### remove existing image
docker rmi dbs2go

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### upload image to docker
docker push USERNAME/dbs2go
```

### kubernetes deployment
Here we provide details how programatically deploy our data-service to
kubernetes cluster. First, we create a pod description in yaml data-format:
```
apiVersion: v1
items:
- apiVersion: extensions/v1beta1
  kind: Deployment
  metadata:
    labels:
      run: kubernetes-dbs2go
    name: kubernetes-dbs2go
  spec:
    selector:
      matchLabels:
        run: kubernetes-dbs2go
    template:
      metadata:
        labels:
          run: kubernetes-dbs2go
      spec:
        containers:
        - image: veknet/dbs2go
          name: kubernetes-dbs2go
          tty: true
          stdin: true
          ports:
          - containerPort: 8989
            protocol: TCP
          volumeMounts:
          - name: secrets
            mountPath: "/etc/secrets"
            readOnly: true
        volumes:
        - name: secrets
          secret:
            secretName: dbs-secrets
kind: List
metadata: {}
resourceVersion: ""
selfLink: ""
```

Then we create dbs secrets we're going to use in our server
```
# create common secret, it contains all necessary secrets files our app will use
# they will be accessible under /etc/secrets within a container
kubectl create secret generic dbs-secrets --from-file=/path/dbfile --from-file=/tmp/dbs-proxy --from-file=server.key --from-file=server.crt

# verify the secret
kubectl get secrets
kubectl describe secret/dbs-secrets

# later we can delete if we wish as following
kubectl delete secret/dbs-secrets
```

When we need to update our secrets on a pod we propose the following method
(it is based on [make_dbs_secret.sh](https://github.com/vkuznet/CMSKubernetes/blob/master/dbs2go/make_dbs_secret.sh) script):
```
# run make_das_secret.sh script to generate new das-secret.yaml file
make_dbs_secret.sh /tmp/das-proxy server.key server.crt /path/dbfile

# apply new secret to the running pod
kubectl apply -f ./dbs-secret.yaml --validate=false
```

Now, let's deploy our app:
```
kubectl apply -f ./kubernetes-dbs2go.yaml --validate=false
# check that our POD is created
kubectl get pods
# get pod description
kubectl describe pod kubernetes-dbs2go-XXX-yyy
# verify our deployment
kubectl get deployments

# we can event login to our app now
kubectl exec -it kubernetes-dbs2go-XXX-yyy bash

# if deployment failed due to lack of disk space we need to clean-up docker images
# first obtain node IP address:
node=`openstack coe cluster show vkcluster | grep node_addresses | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`

# then we can login to our node (under fedora account) and using our ssh key
# and clean-up the node
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@${node} "sudo docker images"

# and finally (if necessary) we can perform clean-up
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@${node} "sudo docker system prune -f -a"
```
To make this app visible outside of kubernetes cluster we do the following:
```
# expose app
kubectl expose deployment/kubernetes-dbs2go --type="NodePort" --port 8989

# find out our external host name
host=`openstack coe cluster show vkcluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"

# find out our external port number
port=`kubectl get services/kubernetes-dbs2go -o go-template='{{(index .spec.ports 0).nodePort}}'`

# and we are ready to go
scurl https://$kubehost:$port/datasets?dataset=/ZMM*/*/*
```
