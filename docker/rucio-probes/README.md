Steps to create image and push to docker hub

* docker login
* export RUCIO_VERSION=1.20.7
* docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-probes:release-$RUCIO_VERSION .
* docker push cmssw/rucio-probes:release-$RUCIO_VERSION

For the NanoAOD version:
* export RUCIO_VERSION=1.21.12
* docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-probes:release-$RUCIO_VERSION.nano1 .
* docker push cmssw/rucio-probes:release-$RUCIO_VERSION.nano1

