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

### run given image
docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t das2go /bin/bash

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
kubectl create secret generic das-proxy --from-file=/tmp/das-proxy

# verify the secret
kubectl get secrets
kubectl describe secret/das-proxy

# later we can delete if we wish as following
kubectl delete secret/das-proxy
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
```

