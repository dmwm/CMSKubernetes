#### How to build

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220421
docker build -t "${docker_registry}/kerberos:${image_tag}" .
# push
docker push "${docker_registry}/kerberos:${image_tag}"
```
