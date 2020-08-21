Steps to create image and push to docker hub

* docker login
* export RUCIO_VERSION=1.22.6.post1
* docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-probes:release-$RUCIO_VERSION .
* docker push cmssw/rucio-probes:release-$RUCIO_VERSION

For the NanoAOD version:
* export RUCIO_VERSION=1.23.2
* export CMS_VERSION=1.23.2.nano1
* docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-probes:release-$CMS_VERSION .
* docker push cmssw/rucio-probes:release-$CMS_VERSION

