Steps to create image and push to docker hub

* docker login
* export RUCIO_VERSION=1.22.8
* docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t cmssw/rucio-sync:release-$RUCIO_VERSION .
* docker push cmssw/rucio-sync:release-$RUCIO_VERSION

For the NanoAOD transition version

* export CMS_VERSION=1.23.2
* docker build  --build-arg RUCIO_VERSION=$CMS_VERSION -t cmssw/rucio-sync:release-$CMS_VERSION .
* docker push cmssw/rucio-sync:release-$CMS_VERSION
