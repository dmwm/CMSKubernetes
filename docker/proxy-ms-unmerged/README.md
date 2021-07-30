Here we present simple list of instructions/commands to build, run and upload
proxy-ms-unmerged docker image. Please replace `USERNAME` with appropriate user name
of your docker account.

```
### build image
docker build -t USERNAME/proxy-ms-unmerged .

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
docker rmi proxy-ms-unmerged

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### upload image to docker
docker push USERNAME/proxy-ms-unmerged

### clean-up docker images
docker system prune -f -a
```
