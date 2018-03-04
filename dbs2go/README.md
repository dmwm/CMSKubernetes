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

### run given image
docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t dbs2go /bin/bash

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
# create common secret from db file (this file contains DB driver login/password)
kubectl create secret generic dbs-secrets --from-file=/path/dbfile

# verify the secret
kubectl get secrets
kubectl describe secret/dbs-secrets

# later we can delete if we wish as following
kubectl delete secret/dbs-secrets
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
```
To make this app visible outside of kubernetes cluster we do the following:
```
# expose app
kubectl expose deployment/kubernetes-dbs2go --type="NodePort" --port 8989

# find out our external host name
host=`openstack coe cluster show vkcluster | grep node_addresses | awk '{print $4}' | sed -e "s,\[u',,g" -e "s,'\],,g"`
kubehost=`host $host | awk '{print $5}'`
echo "Kubernetes host: $kubehost"

# find out our external port number
port=`kubectl get services/kubernetes-dbs2go -o go-template='{{(index .spec.ports 0).nodePort}}'`

# and we are ready to go
scurl https://$kubehost:$port/datasets?dataset=/ZMM*/*/*
```
