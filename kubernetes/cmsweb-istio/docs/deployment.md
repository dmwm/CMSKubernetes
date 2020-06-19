Now, we can deploy our k8s app using `kubectl` command (or `deploy.sh` script
in case of cmsweb deployment).
```
# deploy new application with its app.yaml configuration
kubectl apply -f app.yaml --validate=false

# get list of pods (deployed apps) in default namespace
# here we should get cmsweb app deployed
kubectl get pods
...
# we should see cluster name and Running status
cmsweb-5556f46d6c-phkmq   1/1       Running   0          15h

# get list of pods in kube-system namespace, here we should see traefik/nginx controllers
kubectl get pods -n kube-system
...
# we should see cluster name and traefik/nginx Running status
# example of traefik ingress
ingress-traefik-lk85w                   1/1       Running            0  15h
# example of nginx ingress
ingress-nginx-nginx-ingress-controller-qv8vj                   1/1 Running   0          18d
ingress-nginx-nginx-ingress-default-backend-85474bb488-5s8mb   1/1 Running   0          18d

# get list of deployed services, here we should see our cmsweb with port 80
kubectl get svc
...
# we should see hostname and port mapping
cmsweb       NodePort    10.254.136.150   <none>        8181:30181/TCP   15h

# you may wish to delete your app/pod
kubectl delete app.yaml
```
