#### How to build and push

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220421
docker build -t "${docker_registry}/karma:${image_tag}" .
docker push "${docker_registry}/karma:${image_tag}"
```
