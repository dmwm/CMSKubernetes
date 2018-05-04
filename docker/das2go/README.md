Here we present simple list of instructions/commands to build, run and upload
das2go docker image. Please replace `USERNAME` with appropriate user name
of your docker account.

```
### build image
docker build -t USERNAME/das2go .

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image, here we map local /tmp/das2go area to /etc/secrets in container for app to use
### in this area we can store das-proxy as well as server.{crt,key}
docker run --rm -h `hostname -f` -v /tmp/das2go:/etc/secrets -i -t veknet/dbs2go /bin/bash

### remove existing image
docker rmi das2go

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### upload image to docker
docker push USERNAME/das2go
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
      run: kubernetes-das2go
    name: kubernetes-das2go
  spec:
    selector:
      matchLabels:
        run: kubernetes-das2go
    template:
      metadata:
        labels:
          run: kubernetes-das2go
      spec:
        containers:
        - image: veknet/das2go
          name: kubernetes-das2go
          tty: true
          stdin: true
          ports:
          - containerPort: 8212
            protocol: TCP
          volumeMounts:
          - name: secrets
            mountPath: "/etc/secrets"
            readOnly: true
          env:
            - name: X509_USER_PROXY
              valueFrom:
              secretKeyRef:
                  name: das-proxy
                  key: das-proxy
        volumes:
        - name: secrets
          secret:
            secretName: das-proxy
            defaultMode: 256
kind: List
metadata: {}
resourceVersion: ""
selfLink: ""
```

Then, we create our proxy using `voms-proxy-init -voms cms -rfc` which refer to
`/tmp/x509up_uXXXXX` file. We copy this file to /tmp/das-proxy and, finally, we create proxy secret as following:
```
# create common secret from three files, they will be placed under das-secret name
kubectl create secret generic das-secrets --from-file=/tmp/das-proxy --from-file=server.key --from-file=server.crt

# verify the secret
kubectl get secrets
kubectl describe secret/das-secrets

# later we can delete if we wish as following
kubectl delete secret/das-secrets
```

When we need to update our secrets on a pod we propose the following method
(it is based on [make_das_secret.sh](https://github.com/vkuznet/CMSKubernetes/blob/master/das2go/make_das_secret.sh) script):
```
# run make_das_secret.sh script to generate new das-secret.yaml file
make_das_secret.sh /tmp/das-proxy server.key server.crt

# apply new secret to the running pod
kubectl apply -f ./das-secret.yaml --validate=false
```

Now, let's deploy our app:
```
kubectl apply -f ./kubernetes-das2go.yaml --validate=false
# check that our POD is created
kubectl get pods
# get pod description
kubectl describe pod kubernetes-das2go-XXX-yyy
# verify our deployment
kubectl get deployments

# we can event login to our app now
kubectl exec -it kubernetes-das2go-XXX-yyy bash

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
kubectl expose deployment/kubernetes-das2go --type="NodePort" --port 8212

# find out our external host name
host=`openstack coe cluster show vkcluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}' | sed -e "s,ch.,ch,g"`
echo "Kubernetes host: $kubehost"

# find out our external port number
port=`kubectl get services/kubernetes-das2go -o go-template='{{(index .spec.ports 0).nodePort}}'`

# and we are ready to go
scurl https://$kubehost:$port/das/
```
