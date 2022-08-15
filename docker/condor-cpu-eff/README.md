## condor-cpu-eff

Condor cpu efficiency static pages, including separate step chain calculations.

Resultant page: https://cmsdatapop.web.cern.ch/cmsdatapop/

##### Image built by GH workflow in CMSSpark repository

#### [DEPRECATED] How to build

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220419
docker build -t "${docker_registry}/condor_cpu_eff:${image_tag}" .
# push
docker push "${docker_registry}/condor_cpu_eff:${image_tag}"
```
