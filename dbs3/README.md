Here we present simple list of instructions/commands to build, run and upload
dbs3 docker image. Please replace `USERNAME` with appropriate user name
of your docker account.

```
### build image
docker build -t USERNAME/dbs3 .

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image, here we map local /tmp/dbs3 area to /etc/secrets in container for app to use
### in this area we can store proxy as well as server.{crt,key}
docker run --rm -h `hostname -f` -v /tmp/dbs3:/etc/secrets -i -t veknet/dbs2go /bin/bash

### remove existing image
docker rmi dbs3

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### upload image to docker
docker push USERNAME/dbs3

### clean-up docker images
docker system prune -f -a
```
