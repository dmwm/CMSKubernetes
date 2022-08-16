## cmsmon-rucio-ds

For sending rucio datasets information data to MONIT.

Analytix cluster 3.2, spark3 and python3.9 will be used. Base image already contains sqoop.

Installs:

- stomp.py==7.0.0 and creates its zip for Spark job to submit
- Only src/python/CMSMonitoring cluster of dmwm/CMSMonitoring repo and creates its zip for Spark job to submit
- dmwm/CMSSpark

##### Image built by GH workflow in CMSSpark repository

#### [DEPRECATED] How to build and push

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220418
docker build -t "${docker_registry}/cmsmon-rucio-ds:${image_tag}" .
docker push "${docker_registry}/cmsmon-rucio-ds:${image_tag}"
```
