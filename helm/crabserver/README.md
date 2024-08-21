## Deploy CRAB

At the moment CRAB team is transitioning to using helm. However, we do noy like
to use helm for deployment. See this 
[comment](https://github.com/dmwm/CRABServer/issues/7843#issuecomment-2025085120)
for some context.

We like to use helm for templating, using the helm charts to generate the 
manifest file, then applying it with `kubectl apply`.

We therefore ask cmsweb operators to deploy crab following the procedure at
[1].

Changes to `../../kubernetes/cmsweb/services/crabserver.yaml` should not be committed.

---

[1] https://cmscrab.docs.cern.ch/technical/crab-rest/deploy.html#deploy-on-kubernetes-use-helm-template-to-generate-manifest-preferred

