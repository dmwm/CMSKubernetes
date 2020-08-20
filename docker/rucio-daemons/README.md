Steps to create image and push to docker hub

* docker login
* export RUCIO_VERSION=1.22.7
* docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-daemons:release-$RUCIO_VERSION .
* docker push cmssw/rucio-daemons:release-$RUCIO_VERSION

To build the special release for the NanoAOD conversion

* export CMS_VERSION=1.23.2.nano1
* export RUCIO_VERSION=1.23.2
* docker build -f Dockerfile.nano --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-daemons:release-$CMS_VERSION .
* docker push cmssw/rucio-daemons:release-$CMS_VERSION

