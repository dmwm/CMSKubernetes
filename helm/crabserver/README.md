# Deploy CRAB

In this helm chart, we separate k8s resources into 3 resource groups:

1. `crabserver` manifest for CRAB REST, including `crabserver-canary`.
2. `logPipline`, the log pipeline which have logstash, filebeat and it config.
3. `ciServiceAccount` with deployment permission, for deploying new image from CI. Note that only cluster admin could not `rolebinding` in testbed and production cluster.

CRAB team will only handle the first resources group, `crabserver`, to deploy a new service version or modify how we start our service. The rest we kindly ask cluster admin to take care of.

## Configuration (helm's value)

There are helm value, `enabled`, that is used to control which resource group will be generated.

#### enabled

Default: `true`

Generate `crabserver` resources group.

#### canary.enabled

Default: `false`

Enable canary deployment, a.k.a. the `crabserver-canary` Deployment manifest.

#### logPipeline:enabled

Default: `false`

Generate `logPipeline` resources group.

#### ciServiceAccount.enabled

Generate `ciServiceAccount` resources group. Need cluster admin for applying `role` and `rolebinding`.

## Deploy

### For cluster admins

To deploy everything on new testbed and production cluster:

1. Deploy `crabserver-secrets` credential.

2. Deploy all services:
    ```
    helm install crabserver . -f values.yaml -f values-clusteradmin.yaml --set environment=preprod
    ```
    Please change `environment=preprod` to the cluster you are deploying (`preprod` for testbed and preprod cluster, `prod` for production cluster).

Please leave test cluster to CRAB operators.

### For CRAB operators

Please consult [Deploying CRAB REST](https://cmscrab.docs.cern.ch/crab-components/crab-rest/deploy.html).

## Regarding deploy with `helm install` command

CRAB team does not use helm for deployment. We like to use helm for templating, using the helm charts to generate the manifest file, then applying it with `kubectl apply`. See this [comment](https://github.com/dmwm/CRABServer/issues/7843#issuecomment-2025085120) for some context.

However, it should not have any conflict if cluster admins run `helm install` **before** CRAB operators apply new manifests with `kubectl apply`.

In case of conflict, feel free to purge all resources and reinstall with helm again.
