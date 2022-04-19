Here we present simple list of instructions/commands to build, run and upload
cmsmon docker image. Please replace `USERNAME` with appropriate user name
of your docker account.

```
### build image
docker build -t USERNAME/cmsmon .
### or with specific tag
docker build -t USERNAME/cmsmon:v0.1 cmsmon

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image, here we map local /tmp/cmsmon area to /etc/secrets in container for app to use
### in this area we can store proxy as well as server.{crt,key}
docker run --rm -h `hostname -f` -v /tmp/cmsmon:/etc/secrets -p 127.0.0.1:8181:8181 -i -t veknet/cmsmon /bin/bash

### run docker image detached from stdin/stdout
docker run --rm -h `hostname -f` -p 8181:8181 -d -t veknet/cmsmon

### we can find running containers as following
docker container ls

### we can kill running container as following
docker kill <container_name|container_id>

### remove existing image
docker rmi cmsmon

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### upload image to docker
docker push USERNAME/cmsmon
### or specific tag
docker push USERNAME/cmsmon:v0.1

### clean-up docker images
docker system prune -f -a
```

#### How to build for cern registry

```shell
docker_registry=registry.cern.ch/cmsmonitoring
image_tag=20220421
docker build -t "${docker_registry}/cmsmon:${image_tag}" .
# push
docker push "${docker_registry}/cmsmon:${image_tag}"
```


Docker commands guide can be found
[here](https://docs.docker.com/engine/reference/commandline/docker/)
