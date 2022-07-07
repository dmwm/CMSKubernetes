#! /bin/sh

set -e

export CMS_VERSION=1.28.6.cms1
export RUCIO_VERSION=1.28.6
export CMS_TAG=cms_128_3
export HARBOR=registry.cern.ch/cmsrucio

# Globus Online (need to revisit in 1.26)
#export CMS_VERSION=1.25.4.cmsgo
#export RUCIO_VERSION=1.25.4
#export CMS_TAG=cms_go_dbg

docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t $HARBOR/rucio-server:release-$CMS_VERSION .
docker push $HARBOR/rucio-server:release-$CMS_VERSION

cd ../rucio-daemons
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t $HARBOR/rucio-daemons:release-$CMS_VERSION .
docker push $HARBOR/rucio-daemons:release-$CMS_VERSION

cd ../rucio-probes
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t $HARBOR/rucio-probes:release-$CMS_VERSION .
docker push $HARBOR/rucio-probes:release-$CMS_VERSION

cd ../rucio-ui
docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t $HARBOR/rucio-ui:release-$CMS_VERSION .
docker push $HARBOR/rucio-ui:release-$CMS_VERSION

#cd ../rucio-upgrade
#docker build  --build-arg RUCIO_VERSION=$RUCIO_VERSION -t ericvaandering/rucio-upgrade:release-$CMS_VERSION .
#docker push ericvaandering/rucio-upgrade:release-$CMS_VERSION

