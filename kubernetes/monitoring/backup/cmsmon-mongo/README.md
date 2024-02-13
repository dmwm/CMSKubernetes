## cmsmon-mongo

Refs for the JS and conf files: https://phoenixnap.com/kb/kubernetes-mongodb
#### How to build and push

```shell
# docker image prune -a OR docker system prune -f -a

mongodbver=5.0.9
docker_registry=registry.cern.ch/cmsmonitoring
docker build --build-arg MONGODBVER=${mongodbver} -t "${docker_registry}/cmsmon-mongo:${mongodbver}" .
docker push "${docker_registry}/cmsmon-mongo:${mongodbver}"
```
