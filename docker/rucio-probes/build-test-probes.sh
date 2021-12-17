#! /bin/sh

set -e

export CMS_VERSION=1.27.9.cms1
export RUCIO_VERSION=1.27.9
export CMS_TAG=cms_127_4
export HARBOR=registry.cern.ch/cmsrucio

# Globus Online (need to revisit in 1.26)
#export CMS_VERSION=1.25.4.cmsgo
#export RUCIO_VERSION=1.25.4
#export CMS_TAG=cms_go_dbg

docker build -f Dockerfile.test --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t $HARBOR/rucio-probes-test:release-$CMS_VERSION .
docker push $HARBOR/rucio-probes-test:release-$CMS_VERSION

