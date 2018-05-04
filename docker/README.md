This file describes procedure how to create, deploy and use docker images.

### How to use personal VM for docker builds
You can use OpenStack personal VM to setup docker and make your custom builds.
Full documentation can be found at
[docker](https://docs.docker.com/install/linux/docker-ce/centos/#install-docker-ce-1).
installation guide. Here we describe bare steps you need to do:
```
# install required packages:
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# get docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# install docker CE
sudo yum install docker-ce

# start docker daemon
sudo systemctl start docker

# test docker daemon
sudo docker run hello-world

# setup docker group and add yourself to it
sudo groupadd docker
sudo usermod -aG docker $USER

# test docker from your personal account
docker run hello-world
```

### How to build docker image for CMS data-service
In order to build docker image please login to CMS build (docker) node and
navigate to your favorite directory. The docker commands immitate unix ones
and easy to follow.

The first step is to create a Docker file. Here is an example for
[das2go](https://github.com/vkuznet/CMSKubernetes/blob/master/docker/das2go/Dockerfile) package.

With this file we can build our docker image as following:
```
docker build -t USERNAME/das2go .
```
Here, `USERNAME` should point to your docker username account. This command will build a docker image
in `USERNAME` namespace. Once build we should see it with output from this command:
```
docker images
# to remove all images (including cached ones)
docker rmi $(docker images -qf "dangling=true")
```
Once you have an image app, you can remove it from the docker using the
following command:
```
docker rmi das2go
```
You can inspect the docker container as following:
```
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress
```
To access/run the image we can run the following command:
```
docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t USERNAME/das2go /bin/bash
```
Then you can upload your image to the docker hub:
```
docker push USERNAME/das2go:tagname
```
Here `:tagname` is optional originally, but you may substitute it with any given tag, e.g.
`:v1`. Then login to docker.com and verify that you can see your image.

Finally, if we need to clean-up and/or remove old images we can perform the
following command:
```
sudo docker system prune -f -a
```
