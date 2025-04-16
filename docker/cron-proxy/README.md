Here we present simple list of instructions/commands to build, run and upload
he cro-proxy docker image. Please replace `USERNAME` with appropriate user name
of your docker account.

This image is an updated variation of the one in docker/proxy using a EL9 base image.

```
### build image
docker build -t USERNAME/proxy .

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image, here we map local /tmp/proxy area to /etc/secrets in container for app to use
### in this area we can store proxy as well as server.{crt,key}
docker run --rm -h `hostname -f` -v /tmp/proxy:/etc/secrets -i -t veknet/dbs2go /bin/bash

### remove existing image
docker rmi proxy

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### upload image to docker
docker push USERNAME/proxy

### clean-up docker images
docker system prune -f -a
```
