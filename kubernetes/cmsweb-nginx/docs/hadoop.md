### How to enable access to hadoop cluster on k8s cluster
The [cmsweb image](https://github.com/dmwm/CMSKubernetes/blob/master/docker/cmsweb/Dockerfile)
already contains all necessary libraries to enable Hadoop in your application
or on you pod. What is missing is proper configuration. Here we describe
how to put all pieces together and access your favorite Hadoop cluster.

First, you need to locate proper configuration for your cluster.
Then you can create appropriate config map for you k8s cluster, e.g.
```
# here we use an hadoop analytix configuration and create associative map
# from given location
kubectl create configmap hadoop-analytix --from-file=/path/hadoop/etc/analytix/hadoop.analytix/
```
Then, you should modify your deployment configuration to access this map

```
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  labels:
    app: hadoop
  name: hadoop
spec:
  ...
    spec:
      containers:
      - image: cmssw/crabcache:1.0.3 # replace with appropriate image
        name: hadoop
        ...
        volumeMounts: # create a volume to hold your configuration
        - name: hadoop-analytix
          mountPath: /etc/hadoop/conf
      volumes:
      - name: hadoop-analytix
        configMap: # associate configuration map with proper volume
          name: hadoop-analytix
```
With this change your application will start and be able to access
files on HDFS file system, e.g.
```
hadoop fs -ls /cms
```

A full example of yaml configuration can be found
[here](services/hadoop.yaml).
