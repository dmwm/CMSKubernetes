# Use case:

The following instructions are intended to satisfy a fast pace, fine grained
`code-build-test` development cycle. Aiming to avoid the need of pushing upstream
and creating images and redeploying on every single code change. While at the
same time provide an environment and external services connections as close as possible
to the production setup.

# High level overview:

* Bring up a hollow dev container with empty executable
* Redirect the service ingress by changing the service `app-selector` so that it starts pointing to the new and still empty container
* Investigate/code in your local tree - use AI tools for assistance if you'd like (no pushes, no commits, no tags or whatever upstream)
* Build locally for the proper arch you are about to test
* Push the binary into the container
* Test/validate with real data
* Repeat until you reach code quality satisfactory level
* Revert the redirection
* Commit/push upstream, tag, create images, redeploy fresh

# Procedure:

# 1. Checkout to the proper CMSKubernetes branch and move to the correct working directory

```bash
cd CMSKubernetes/kubernetes/cmsweb/services/
```

# 2. Kubernetes operational instructions for deploying and running a das-server-dev container

## 2.0 Set the proper K8 environment

 - For working on the testbed cluster:

```bash
export KUBECONFIG=users_config/config.preprod/config.cmsweb-testbed-backend
```

or

 - For working on one of the developer's  clusters:

```bash
export OS_PROJECT_NAME="CMS Webtools Mig";
export KUBECONFIG=$workPath/users_config/config.test1/config.cmsweb-test1
```

## 2.1 Verify existing dependencies

```bash
kubectl -n das get service das-mongo
kubectl -n das get service das-server
kubectl -n das get secret das-server-secrets proxy-secrets robot-secrets hmac-secrets token-secrets
```

Expected: all should exist.

## 2.2 Bring up `das-server-dev`

```bash
kubectl -n das apply -f das-server-dev.yaml
kubectl -n das rollout status deployment/das-server-dev
```

Check pod:

```bash
kubectl -n das get pods -l app=das-server-dev -o wide
```

Set helper variable:

```bash
POD=$(kubectl -n das get pod -l app=das-server-dev -o jsonpath='{.items[0].metadata.name}')
echo "$POD"
```

Check mounted secrets and DNS:

```bash
kubectl -n das exec "$POD" -c dev -- ls -l /etc/secrets /etc/proxy /etc/robots /etc/hmac /etc/token
kubectl -n das exec "$POD" -c dev -- nslookup das-mongo.das.svc.cluster.local
```

## 2.3 Optional: scale down current `das-server`

**NOTE:** This step should be avoided in the case where one will workaround the
Frontend redirection rules and ingress policy, by switching the `app-selector` for
the currently running `das-server` service.

Do this only if you want to avoid two DAS servers running at once.

Record current replica count first:

```bash
kubectl -n das get deployment das-server
```

Scale production `das-server` down:

```bash
kubectl -n das scale deployment/das-server --replicas=0
kubectl -n das rollout status deployment/das-server
```

Bring it back later:

```bash
kubectl -n das scale deployment/das-server --replicas=1
kubectl -n das rollout status deployment/das-server
```

## 2.5 Logs / shell

Shell into dev pod:

```bash
kubectl -n das exec -it "$POD" -c dev -- /bin/bash
```

Follow pod output:

```bash
kubectl -n das logs deployment/das-server-dev -c dev -f
```

Delete dev deployment when finished:

```bash
kubectl -n das delete -f das-server-dev.yaml
```

---

# 3. Recreate `das-server` runtime payload manually inside `das-server-dev`

This mirrors the runtime content produced by the `docker/das-server/Dockerfile`:

```text
/data/das2go
/data/das2go_monitor
/data/js
/data/css
/data/images
/data/templates
/data/examples
```

## 3.1 Build locally from your working `das2go` tree

On your Linux dev machine checkout the desired branch/commit of das2go and move to the correct directory:

```bash
cd ~/das2go
git checkout <dev-branch-name>
make
```

Build monitor binary too:

```bash
go build \
  -o das2go_monitor \
  -ldflags="-s -w -extldflags -static" \
  ./monitor/das2go_monitor.go
```

Verify local outputs:

```bash
ls -l ./das2go ./das2go_monitor
ls -ld ./js ./css ./images ./templates ./examples
```

## 3.2 Copy full runtime payload into `das-server-dev`

Refresh pod variable:

```bash
POD=$(kubectl -n das get pod -l app=das-server-dev -o jsonpath='{.items[0].metadata.name}')
```

Clean `/data` first:

```bash
kubectl -n das exec "$POD" -c dev -- rm -rf \
  /data/das2go \
  /data/das2go_monitor \
  /data/js \
  /data/css \
  /data/images \
  /data/templates \
  /data/examples
```

Copy binaries:

**NOTE:** It is supposed that before you start the deployment you've already
    pre-compiled the service executable for the correct arch as it will be run
    inside the container.

```bash
kubectl -n das cp ./das2go "$POD":/data/das2go -c dev
kubectl -n das cp ./das2go_monitor "$POD":/data/das2go_monitor -c dev
```

Copy runtime directories:

```bash
kubectl -n das cp ./js "$POD":/data/js -c dev
kubectl -n das cp ./css "$POD":/data/css -c dev
kubectl -n das cp ./images "$POD":/data/images -c dev
kubectl -n das cp ./templates "$POD":/data/templates -c dev
kubectl -n das cp ./examples "$POD":/data/examples -c dev
```

Make binaries executable:

```bash
kubectl -n das exec "$POD" -c dev -- chmod +x /data/das2go /data/das2go_monitor
```

Verify inside pod:

```bash
kubectl -n das exec "$POD" -c dev -- ls -l /data
kubectl -n das exec "$POD" -c dev -- ls -ld /data/js /data/css /data/images /data/templates /data/examples
```

## 3.3 Run manually inside pod

Open shell:

```bash
kubectl -n das exec -it "$POD" -c dev -- /bin/bash
```

Inside pod:

```bash
cd /data
./das2go -config /etc/secrets/dasconfig.json
```


### 3.3.1 Port-forward of the dev service to local host for access testing

After `/data/das2go` is copied and running inside the pod:

```bash
kubectl -n das port-forward service/das-server-dev 8217:8217
```

In another terminal:

```bash
curl -sS http://127.0.0.1:8217/das
```

Other useful checks:

```bash
curl -v http://127.0.0.1:8217/das
```


## 3.4 Rapid edit/build/test loop

On local dev machine:

```bash
cd ~/das2go

# edit code
make

POD=$(kubectl -n das get pod -l app=das-server-dev -o jsonpath='{.items[0].metadata.name}')

kubectl -n das cp ./das2go "$POD":/data/das2go -c dev
kubectl -n das exec "$POD" -c dev -- chmod +x /data/das2go
```

Inside the pod shell where `das2go` is running:

```bash
Ctrl-C
cd /data
./das2go -config /etc/secrets/dasconfig.json
```

Only recopy static/runtime directories when they changed:

```bash
kubectl -n das cp ./js "$POD":/data/js -c dev
kubectl -n das cp ./css "$POD":/data/css -c dev
kubectl -n das cp ./images "$POD":/data/images -c dev
kubectl -n das cp ./templates "$POD":/data/templates -c dev
kubectl -n das cp ./examples "$POD":/data/examples -c dev
```

## 3.5 Optional: run `das2go_monitor`

Only if needed:

```bash
cd /data
./das2go_monitor
```

For the main server test path, the essential command is still:

```bash
cd /data
./das2go -config /etc/secrets/dasconfig.json
```

# 4. Work around ingress rules and Frontend redirection paths so that you can test real access and service behavior from outside e.g. https://cmsweb-test1.cern.ch/das

**NOTE:** The goal here is:
    * leave ingress untouched
    * leave frontend untouched
    * make existing service/das-server route to `app=das-server-dev` instead of `app=das-serever`

**Reason:** `ing-das.yaml` routes `/das` on `cmsweb-srv.cern.ch` to service `das-server` port `8217`; it does not know about pods directly and does not know about `das-server-dev`. ([GitHub][1])

So one does **not** need frontend/ingress access rights. The only need rights are to patch the **Service selector** in namespace `das`.

## Redirect external `/das` traffic to the new dev pod

First record current selector:

```bash
kubectl -n das get service das-server -o yaml
```

Patch `service/das-server` to select dev pods:

```bash
kubectl -n das patch service das-server \
  -p '{"spec":{"selector":{"app":"das-server-dev"}}}'
```

Verify endpoints switched:

```bash
kubectl -n das get endpoints das-server -o wide
kubectl -n das get pods -l app=das-server-dev -o wide
```

The endpoint IP behind `service/das-server` should now match the `das-server-dev` pod IP.

## Test through the real external path

Use the real ingress/frontend URL, not port-forward, because ingress still points to `service/das-server`:

```bash
curl -v https://cmsweb-testbed.cern.ch/das
```

or whatever external test-cluster host maps to the same ingress/service path.

## Roll back to production pods

```bash
kubectl -n das patch service das-server \
  -p '{"spec":{"selector":{"app":"das-server"}}}'
```

Verify:

```bash
kubectl -n das get endpoints das-server -o wide
kubectl -n das get pods -l app=das-server -o wide
```

[1]: https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/ingress/ing-das.yaml "CMSKubernetes/kubernetes/cmsweb/ingress/ing-das.yaml at master · dmwm/CMSKubernetes · GitHub"
