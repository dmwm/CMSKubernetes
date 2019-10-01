Steps to create image and push to docker hub

* docker login
* export RUCIO_VERSION=1.20.1
* docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-daemons:release-$RUCIO_VERSION .
* docker push cmssw/rucio-daemons:release-$RUCIO_VERSION
