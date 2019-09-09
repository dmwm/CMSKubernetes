This file describes procedure how to create, deploy and use docker images
for cmsweb services.

### Common structure
Each cmsweb data-service area contains a common structure such as
```
Dockerfile # file with recipe how to build docker image
install.sh # install script to deploy cmswen RPMs
monitor.sh # monitor script to run monitoring processes
run.sh     # run script to run your service
```
Each cmsweb services, e.g. das, dbs, etc., is based on cmsweb image.
The later is defined in `cmsweb` directory and its `Dockerfile`
contains list of RPMs we deploy. The `install.sh` immitate `deploy`
script of VM based cmsweb procedure, i.e. it defines tag to use,
bootstrap the install area, and perform pre/sw/post install
procedures based on `cfg/Deploy` script. All scripts for specific
cmsweb services are alike and only differ in some concrete details
required for cmsweb services. Therefore if you need to deploy a new
service we suggest that you create your service area based on existing
ones and adjust it if necessary.

Most likely, in order to get new image you'll only required to change
the following lines in your service `install.sh` file:
```
# example is taken from dbs/install.sh script
ARCH=slc7_amd64_gcc630
VER=HG1907f
REPO="comp"
AREA=/data/cfg/admin
PKGS="admin backend dbs"
SERVER=cmsrep.cern.ch
```
Here you can change your architecture, tag version, repository and list of
packages you service depend on.

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
[das](https://github.com/vkuznet/CMSKubernetes/blob/master/docker/das/Dockerfile) package.

With this file we can build our docker image as following:
```
# By default build.sh will build docker images to all cmsweb services
# and upload them to cmssw repository. But you can specify your set of packages
build.sh "pkg1 pkg2"

# once your build is complete please make sure that you tag it appropriately
# you can do it as following
CMSK8STAG=1.1.1 build.sh "pkg1 pkg2"

# finally, by default build.sh script builds packages using
# http://cmsweb-test.web.cern.ch host name for all internal settings (e.g. in
# frontend deploy scripts). You may change it via
CMSK8S=http://your.host.com build.sh "pkg1 pkg2"
```

```
# here we need to pass hostname of k8s host we're going to use
# e.g. https://cmsweb-test.web.cern.ch
# here USERNAME/das represents docker repository and das is local directory
docker build --build-arg CMSK8S=<hostname> -t USERNAME/das das

# to build tagged version of the image use this command
docker build --build-arg CMSK8S=<hostname> -t USERNAME/das -t USERNAME/das:TAG das
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
docker rmi das
```
You can inspect the docker container as following:
```
docker ps # find docker id
docker inspect <docker_id> | grep IPAddress
```
To access/run the image we can run the following command:
```
docker run --rm -h `hostname -f` -v /tmp:/tmp -i -t USERNAME/das /bin/bash
```
Then you can upload your image to the docker hub:
```
docker push USERNAME/das:tagname
```
Here `:tagname` is optional originally, but you may substitute it with any given tag, e.g.
`:v1`. Then login to docker.com and verify that you can see your image.

If you have running docker containers on your node you may stop them as following:
```
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

Finally, if we need to clean-up and/or remove old images we can perform the
following command:
```
sudo docker system prune -f -a
```
