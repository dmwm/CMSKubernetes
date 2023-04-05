## CMSKubernetes
This repository contains all necessary tools and documentation to
build and deploy cms services to kubernetes (k8s). The repository
is organized in the following way:

- [docker](https://github.com/dmwm/CMSKubernetes/tree/master/docker)
area contains cmsweb service areas. Within individual area you'll find
Dockerfile and aux files required to build docker image for that service
- [kubernetes](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes)
area contains several projects for deploying cmsweb service to k8s.
Even though some of them are obsolete now we still keep them around for
the reference.
  - [kubernetes/cmsweb](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/cmsweb)
  area contains all documentation about **current cmsweb k8s deployment**. 
  - [kubernetes/rucio](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/rucio)
  area contains all files required for Rucio deployment.
  - [kuberentes/tfaas](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/tfaas)
  provides all files for [TFaaS](https://github.com/vkuznet/TFaaS) k8s setup.
  - [kubernetes/cmsmon](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/cmsmon)
  contains files for cmsmon service on k8s.
  - [kubernetes/monitoring](https://github.com/dmwm/CMSKubernetes/blob/master/kubernetes/monitoring)
  presents the CMS Monitoring cluster architecture and contains all the relevant files for the deployment of a monitoring cluster.
    - [kubernetes/traefik](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/legacy) 
    contains the legacy code of cmsweb.
  - [kubernetes/whoami](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/whoami)
  area contains all details of end-to-end deployment of cluster running two services httpgo and its httpsgo counterpart.
  <!---
  - [kubernetes/k8s-whoami-nginx](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/k8s-whoami-nginx)
  area contains all files required for simple k8s whoami service based on nginx
  middleware
   - [kubernetes/traefik](https://github.com/dmwm/CMSKubernetes/tree/master/kubernetes/cmsweb-nginx)
  area contains previous cmsweb deployment using traefik middleware
  --->

- [helm](https://github.com/dmwm/CMSKubernetes/tree/master/helm) area contains helm files for all the cmsweb services.
