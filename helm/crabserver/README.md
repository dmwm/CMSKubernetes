## Deploy CRAB

At the moment CRAB team is transitioning to using helm. However, we do noy like
to use helm for deployment. See this 
[comment](https://github.com/dmwm/CRABServer/issues/7843#issuecomment-2025085120)
for some context.

We like to use helm for templating, using the helm charts to generate the 
manifest file, then applying it with `kubectl apply`.

We therefore ask cmsweb operators to deploy crab with the following procedure:

Generate the manifest with

```bash
# testbed
helm template crabserver . -f values.yaml -f values-testbed.yaml > ../../kubernetes/cmsweb/services/crabserver.yaml

# prod
helm template crabserver . -f values.yaml -f values-prod.yaml > ../../kubernetes/cmsweb/services/crabserver.yaml
```

Then to deploy it with the usual `deploy-srv.sh` script

```bash
# testbed
./scripts/deploy-srv.sh crabserver v3.231006 preprod

# prod
./scripts/deploy-srv.sh crabserver v3.231006 prod
```

Changes to `../../kubernetes/cmsweb/services/crabserver.yaml` should not be committed.
