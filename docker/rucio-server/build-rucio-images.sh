#! /bin/sh

set -e

export CMS_VERSION=1.26.2.cms1
export RUCIO_VERSION=1.26.2
export CMS_TAG=cms_126_1

# Globus Online (need to revisit in 1.26)
#export CMS_VERSION=1.25.4.cmsgo
#export RUCIO_VERSION=1.25.4
#export CMS_TAG=cms_go_dbg

docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-server:release-$CMS_VERSION .
docker push cmssw/rucio-server:release-$CMS_VERSION

cd ../rucio-daemons
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-daemons:release-$CMS_VERSION .
docker push cmssw/rucio-daemons:release-$CMS_VERSION

cd ../rucio-probes
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-probes:release-$CMS_VERSION .
docker push cmssw/rucio-probes:release-$CMS_VERSION

cd ../rucio-ui
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t cmssw/rucio-ui:release-$CMS_VERSION .
docker push cmssw/rucio-ui:release-$CMS_VERSION

#cd ../rucio-upgrade
#docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t ericvaandering/rucio-upgrade:release-$CMS_VERSION .
#docker push ericvaandering/rucio-upgrade:release-$CMS_VERSION

