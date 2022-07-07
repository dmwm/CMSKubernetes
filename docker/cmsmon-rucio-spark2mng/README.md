## cmsmon-rucio-spark2mng

For sending rucio datasets Spark results to MongoDB (cmsmon-mongo).

Analytix cluster 3.2, spark3 and python3.9 will be used. Base image already contains sqoop.

Installs:

- dmwm/CMSSpark
- mongoimport CLI

##### This docker image is built by GH workflow in dmwm/CMSSpark repo

#### [Deprecated] How to build and push

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220616
docker build -t "${docker_registry}/cmsmon-rucio-spark2mng:${image_tag}" .
docker push "${docker_registry}/cmsmon-rucio-spark2mng:${image_tag}"
```
