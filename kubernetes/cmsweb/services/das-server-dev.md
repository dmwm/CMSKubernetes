# 1. Checkout to the proper CMSKubernetes branch and move to the correct working directory
```bash
cd CMSKubernetes/kubernetes/cmsweb/services/
```

# 2. Kubernetes operational instructions with for deploying and running das-server-dev

## 2.0 Set the proper K8 environment

```bash
k8init preprod

```

## 2.1 Verify existing dependencies

```bash
kctl -n das get service das-mongo
kctl -n das get service das-server
kctl -n das get secret das-server-secrets proxy-secrets robot-secrets hmac-secrets token-secrets
```

Expected: all should exist.

## 2.2 Bring up `das-server-dev`

```bash
kctl -n das apply -f das-server-dev.yaml
kctl -n das rollout status deployment/das-server-dev
```

Check pod:

```bash
kctl -n das get pods -l app=das-server-dev -o wide
```

Set helper variable:

```bash
POD=$(kctl -n das get pod -l app=das-server-dev -o jsonpath='{.items[0].metadata.name}')
echo "$POD"
```

Check mounted secrets and DNS:

```bash
kctl -n das exec "$POD" -c dev -- ls -l /etc/secrets /etc/proxy /etc/robots /etc/hmac /etc/token
kctl -n das exec "$POD" -c dev -- nslookup das-mongo.das.svc.cluster.local
```

## 2.3 Optional: scale down current `das-server`

**NOTE:** This step should be avoided in the case where one will workaround the
Frontend redirection rules and ingress policy, by switching the `app-selector` for
the currently running `das-server` service.

Do this only if you want to avoid two DAS servers running at once.

Record current replica count first:

```bash
kctl -n das get deployment das-server
```

Scale production `das-server` down:

```bash
kctl -n das scale deployment/das-server --replicas=0
kctl -n das rollout status deployment/das-server
```

Bring it back later:

```bash
kctl -n das scale deployment/das-server --replicas=1
kctl -n das rollout status deployment/das-server
```

## 2.4 Port-forward dev service

After `/data/das2go` is copied and running inside the pod:

```bash
kctl -n das port-forward service/das-server-dev 8217:8217
```

In another terminal:

```bash
curl -sS http://127.0.0.1:8217/das
```

Other useful checks:

```bash
curl -v http://127.0.0.1:8217/das
```

## 2.5 Logs / shell

Shell into dev pod:

```bash
kctl -n das exec -it "$POD" -c dev -- /bin/bash
```

Follow pod output:

```bash
kctl -n das logs deployment/das-server-dev -c dev -f
```

Delete dev deployment when finished:

```bash
kctl -n das delete -f das-server-dev.yaml
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
POD=$(kctl -n das get pod -l app=das-server-dev -o jsonpath='{.items[0].metadata.name}')
```

Clean `/data` first:

```bash
kctl -n das exec "$POD" -c dev -- rm -rf \
  /data/das2go \
  /data/das2go_monitor \
  /data/js \
  /data/css \
  /data/images \
  /data/templates \
  /data/examples
```

Copy binaries:

```bash
kctl -n das cp ./das2go "$POD":/data/das2go -c dev
kctl -n das cp ./das2go_monitor "$POD":/data/das2go_monitor -c dev
```

Copy runtime directories:

```bash
kctl -n das cp ./js "$POD":/data/js -c dev
kctl -n das cp ./css "$POD":/data/css -c dev
kctl -n das cp ./images "$POD":/data/images -c dev
kctl -n das cp ./templates "$POD":/data/templates -c dev
kctl -n das cp ./examples "$POD":/data/examples -c dev
```

Make binaries executable:

```bash
kctl -n das exec "$POD" -c dev -- chmod +x /data/das2go /data/das2go_monitor
```

Verify inside pod:

```bash
kctl -n das exec "$POD" -c dev -- ls -l /data
kctl -n das exec "$POD" -c dev -- ls -ld /data/js /data/css /data/images /data/templates /data/examples
```

## 3.3 Run manually inside pod

Open shell:

```bash
kctl -n das exec -it "$POD" -c dev -- /bin/bash
```

Inside pod:

```bash
cd /data
./das2go -config /etc/secrets/dasconfig.json
```

## 3.4 Rapid edit/build/test loop

On local dev machine:

```bash
cd ~/das2go

# edit code
make

POD=$(kctl -n das get pod -l app=das-server-dev -o jsonpath='{.items[0].metadata.name}')

kctl -n das cp ./das2go "$POD":/data/das2go -c dev
kctl -n das exec "$POD" -c dev -- chmod +x /data/das2go
```

Inside the pod shell where `das2go` is running:

```bash
Ctrl-C
cd /data
./das2go -config /etc/secrets/dasconfig.json
```

Only recopy static/runtime directories when they changed:

```bash
kctl -n das cp ./js "$POD":/data/js -c dev
kctl -n das cp ./css "$POD":/data/css -c dev
kctl -n das cp ./images "$POD":/data/images -c dev
kctl -n das cp ./templates "$POD":/data/templates -c dev
kctl -n das cp ./examples "$POD":/data/examples -c dev
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

# 4. Work around ingress rules and Frontend redirection paths

**NOTE:** The goal here is:
    * leave ingress untouched
    * leave frontend untouched
    * make existing service/das-server route to `app=das-server-dev` instead of `app=das-serever`

**Reason:** `ing-das.yaml` routes `/das` on `cmsweb-srv.cern.ch` to service `das-server` port `8217`; it does not know about pods directly and does not know about `das-server-dev`. ([GitHub][1])

So one does **not** need frontend/ingress access rights. The only need rights are to patch the **Service selector** in namespace `das`.

## Redirect external `/das` traffic to the new dev pod

First record current selector:

```bash
kctl -n das get service das-server -o yaml
```

Patch `service/das-server` to select dev pods:

```bash
kctl -n das patch service das-server \
  -p '{"spec":{"selector":{"app":"das-server-dev"}}}'
```

Verify endpoints switched:

```bash
kctl -n das get endpoints das-server -o wide
kctl -n das get pods -l app=das-server-dev -o wide
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
kctl -n das patch service das-server \
  -p '{"spec":{"selector":{"app":"das-server"}}}'
```

Verify:

```bash
kctl -n das get endpoints das-server -o wide
kctl -n das get pods -l app=das-server -o wide
```

[1]: https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/cmsweb/ingress/ing-das.yaml "CMSKubernetes/kubernetes/cmsweb/ingress/ing-das.yaml at master · dmwm/CMSKubernetes · GitHub"
