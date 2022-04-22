#### How to build

```shell
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=v0.0.75
docker build -t "${docker_registry}/promxy:${image_tag}" .
# push
docker push "${docker_registry}/promxy:${image_tag}"
```
