Steps to create image and push to docker hub

* docker login
* export RUCIO_VERSION=1.21.3
* docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t ericvaandering/rucio-upgrade:release-$RUCIO_VERSION .
* docker push ericvaandering/rucio-upgrade:release-$RUCIO_VERSION
