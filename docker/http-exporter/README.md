#### How to build

```shell
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220420
docker build -t "${docker_registry}/http-exporter:${image_tag}" .
# push
docker push "${docker_registry}/http-exporter:${image_tag}"
```
