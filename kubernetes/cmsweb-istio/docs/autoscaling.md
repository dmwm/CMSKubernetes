### Add autoscale for certain pods
In order to turn on pods' autoscaling you need to implement proper
`resources` specs in your application yaml file. Please refer to
[Resources](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)
documentation how to do it. Once your pod is deployed 
we can turn on autoscale of pods via the following command (here we use dbs as
an example):
```
# example how to scale dbs app to 3 pods if its CPU usage will exceed 50%
kubectl autoscale deployment dbs --cpu-percent=50 --min=1 --max=3
```
To check the autoscale we use the following command
```
kubectl get hpa
```
and it should yield the following information
```
NAME  REFERENCE        TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
dbs   Deployment/dbs   5%/50%    1         3         1          3h38m
```
which shows current load (5%) and CPU threshold (50%) along
with number of current pods/replicas. We can delete autoscaling
(if necessary) as following
```
kubectl delete hpa dbs
```
