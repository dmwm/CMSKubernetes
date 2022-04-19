#### How to build for cern registry

```shell
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220421
docker build -t "${docker_registry}/log-clustering:${image_tag}" .
# push
docker push "${docker_registry}/log-clustering:${image_tag}"
```
