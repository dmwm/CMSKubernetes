#### How to build and push

**Note**

Build by github wf action in dmwm/CMSMonitoring repository

---

**Warning [DEGRADED]**

```shell
# docker image prune -a OR docker system prune -f -a
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220421
docker build -t "${docker_registry}/nats-sub:${image_tag}" .
docker push "${docker_registry}/nats-sub:${image_tag}"
```
