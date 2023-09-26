#!/bin/bash

### This script is to be used for building a WMAgent docker imagge based on pypi
### It depends on a single parameter WMA_TAG, which is to be passed to the basic
### WMAgent deployment script install.sh at build time through `docker --build-arg`


help(){
    echo -e $*
    cat <<EOF

The WMAgent docker build script for Docker image creation based on pypi:

Usage: wmagent-docker-build.sh -t <wmagent_tag>

    -t <wmagent_tag>                The WMAgent version/tag to be used for the Docker image creation
    -p <push_image>                 Push the image to registry.cern.ch
    -l <latest_tag_toregistry>      Push the curernt tag also as latest to registry.cern.ch

Example: ./wmagent-docker-build.sh -v 2.2.0.2

EOF
}

usage(){
    help $*
    exit 1
}

WMA_TAG=None
PUSH=false
LATEST=false

### Argument parsing:
while getopts ":t:hpl" opt; do
    case ${opt} in
        t) WMA_TAG=$OPTARG ;;
        p) PUSH=true ;;
        l) LATEST=true ;;
        h) help; exit $? ;;
        \? )
            msg="Invalid Option: -$OPTARG"
            usage "$msg" ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done


# NOTE: NO WMA_TAG validation is done in the current script. It is implemented at the install.sh

dockerOpts=" --network=host --progress=plain --build-arg WMA_TAG=$WMA_TAG "

docker build $dockerOpts -t local/wmagent:$WMA_TAG -t local/wmagent:latest  .

$PUSH && {
    docker login registry.cern.ch
    docker tag local/wmagent:$WMA_TAG registry.cern.ch/cmsweb/wmagent:$WMA_TAG
    echo "Uploading image registry.cern.ch/cmsweb/wmagent:$WMA_TAG"
    docker push registry.cern.ch/cmsweb/wmagent:$WMA_TAG
    $LATEST &&  {
        docker tag local/wmagent:$WMA_TAG registry.cern.ch/cmsweb/wmagent:latest
        echo "Uploading image registry.cern.ch/cmsweb/wmagent:latest"
        docker push registry.cern.ch/cmsweb/wmagent:latest
    }
}
