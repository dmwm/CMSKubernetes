##### Troubleshooting
If you find that some of the pods didn't start you may use the following
commands to trace down the problem:
```
# get list of pods, secrets, ingress
kubectl get pods
kubectl get secrets
kubectl get ing

# Please note there are multiple namespace, default one, kube-system
# where all network controllers are and additional ones like monitoring
# you can inspect pods, secrets, etc in these namespace by using -n flag, e.g.
kubectl -n kube-system get pods

# get description of pod,secret,ingress
kubectl describe pod/<pod_name>
kubectl describe ing/<ingress_name>
kubectl describe secrets/<secret_name>

# get log information from the pod
kubectl logs <pod_name>
# here is concrete example of producing logs from ingress-nginx in kube-system namespace
kubectl -n kube-system logs ingress-nginx-nginx-ingress-controller-s2rrk

# if necessary you can login to your pod as following:
kubectl exec -ti <pod_name> bash
# here is a concrete example
kubectl exec -ti httpsgo-deployment-5b654d8f99-lfmg5 bash

# you can login into your minion node too, e.g.
# obtain minion name
kubectl get node | grep minion

# with that name login to it as following (change your ssh file you used to
# create k8s and substitute the minion_name
ssh -i ~/.ssh/cloud -o ConnectTimeout=30 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no fedora@<minion_name>
```
