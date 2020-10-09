### How to setup auth daemonset instead of ingress
The daemonset can be applied to all k8s nodes. Instead of using nginx,
we can use our own http server to handle incoming requests for us, e.g.
it can be apache or any other server(s). Here we provide instructions
how to setup custom daemon set instead of nginx-controller one.

If node is already has nginx ingress-controller we need:
- stop ingress-controller
```
k get ds -n kube-system
k delete ds -n kube-system
```

Then, we should create a new label role for our nodes:
- remove ingress label on nodes and apply new role=auth
```
k get nodes | grep node | awk '{print $1}' | awk '{print "kubectl label node "$1" role=auth --overwrite"}'
```
Please note, that only nodes with `role=auth` will be used to run our
daemonset (this is controlled in k8s manifest files through nodeSelector
settings).

Now, we should be able to start new daemonset
```
k deploy -f daemonset/x509-proxy-server.yaml
k deploy -f daemonset/auth-proxy-server.yaml
```

#### References
[k8s daemonset](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
