#! /bin/sh

set -e

export CMS_VERSION=1.24.5.nano1
export RUCIO_VERSION=1.24.5
export CMS_TAG=cms_nano13


docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-server:release-$CMS_VERSION  -f Dockerfile.nano .
docker push cmssw/rucio-server:release-$CMS_VERSION

cd ../rucio-daemons
docker build -f Dockerfile.nano --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-daemons:release-$CMS_VERSION .
docker push cmssw/rucio-daemons:release-$CMS_VERSION

cd ../rucio-probes
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-probes:release-$CMS_VERSION .
docker push cmssw/rucio-probes:release-$CMS_VERSION

cd ../rucio-sync
docker build --build-arg RUCIO_VERSION=$CMS_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-sync:release-$CMS_VERSION .
docker push cmssw/rucio-sync:release-$CMS_VERSION

cd ../rucio-ui
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-ui:release-$CMS_VERSION -f Dockerfile.nano .
docker push cmssw/rucio-ui:release-$CMS_VERSION

cd ../rucio-upgrade
docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t ericvaandering/rucio-upgrade:release-$CMS_VERSION .
docker push ericvaandering/rucio-upgrade:release-$CMS_VERSION

