#!/bin/sh


set -e

export CONSISTENCY_VERSION=1.1.2
export HARBOR=registry.cern.ch/cmsrucio

# Globus Online (need to revisit in 1.26)
#export CMS_VERSION=1.25.4.cmsgo
#export RUCIO_VERSION=1.25.4
#export CMS_TAG=cms_go_dbg

#docker build --build-arg RUCIO_VERSION=$RUCIO_VERSION --build-arg CMS_TAG=$CMS_TAG -t $HARBOR/rucio-server:release-$CMS_VERSION .                                                                        
#docker push $HARBOR/rucio-server:release-$CMS_VERSION



docker build -t $HARBOR/rucio-consistency:release-$CONSISTENCY_VERSION .
docker push $HARBOR/rucio-consistency:release-$CONSISTENCY_VERSION 
