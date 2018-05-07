

### build image
docker build -t veknet/dbs2go .

### list images
docker images

### list of running containers
docker ps --no-trunc -aq

### remove all running containers
docker rm -f `docker ps --no-trunc -aq`

### run given image
docker run --rm -h `hostname -f` -v /tmp/dbs2go:/etc/secrets -i -t veknet/dbs2go /bin/bash
### within a container app we can query DBS
curl -k --key /etc/secrets/dbs-proxy --cert /etc/secrets/dbs-proxy "https://localhost:8989/dbs/datasets?dataset=/ZMM*/*/*"

### remove existing image
docker rmi veknet/dbs2go
### remove all images
docker rmi $(docker images -qf "dangling=true")

### inspect running container
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress

### references
https://stackoverflow.com/questions/18497688/run-a-docker-image-as-a-container#18498313
https://stackoverflow.com/questions/17236796/how-to-remove-old-docker-containers#17237701
http://goinbigdata.com/docker-run-vs-cmd-vs-entrypoint/
