#!/bin/bash

### This script is to be used for building a CouchDB docker image based on pypi
### It depends on a single parameter WMA_TAG, which is to be passed to the basic
### CouchDB deployment script install.sh at build time through `docker --build-arg`


help(){
    echo -e $*
    cat <<EOF

The CouchDB docker build script for Docker image creation based on pypi:

Usage: couchdb-docker-build.sh -t <couchdb_tag> [-p]

    -t <couch_tag>  The Couchdb (upstream tag) tag to base this this image on
    -p              Push the CouchDB image to registry.cern.ch
    -l              Push the current tag also as latest to registry.cern.ch
    -h <help>       Provides this help

Example: ./couchdb-docker-build.sh -t 3.2.2

EOF
}

usage(){
    help $*
    exit 1
}

TAG=3.2.2
PUSH=false
LATEST=false

### Argument parsing:
while getopts ":t:hpl" opt; do
    case ${opt} in
        t) TAG=$OPTARG ;;
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

# NOTE: The COUCH_USER may refer to both the couch user to run the CouchDB
#       service inside the container and to the database admin user as well
# dockerOpts=" --network=host --progress=plain --build-arg COUCH_USER=$COUCH_USER  --build-arg COUCH_PASS=$COUCH_PASS --build-arg TAG=$TAG"
dockerOpts=" --network=host --progress=plain --build-arg TAG=$TAG"

registry=local
repository=wmagent-couchdb

docker build $dockerOpts -t $registry/$repository:$TAG -t $registry/$repository:latest  .

$PUSH && {
    # For security reasons we check if the login name and the current user match.
    # If they do not, abort the execution and push nothing to registry.cern.ch.
    loginUser=`logname`
    currUser=`id -un`
    localReg=$registry
    registry=registry.cern.ch
    project=cmsweb
    [[ $loginUser == $currUser ]] || {
        echo "ERROR: The CURRENT and the LOGIN users do not match!"
        echo "ERROR: You MUST connect to $registry with your login user rather than with $currUser"
        exit 1
    }
    echo "Testing for existing login session to $registry with Username: $loginUser"
    docker login $registry < /dev/null >/dev/null 2>&1 || {
        echo "ERROR: A valid login session to $registry is required in order to be able to upload any docker image"
        echo "ERROR: Please consider running 'docker login $registry' with USER:$currUser and retry again."
        exit 1
    }
    docker tag $localReg/$repository:$TAG $registry/$project/$repository:$TAG
    echo "Uploading image $registry/$project/$repository:$TAG"
    docker push $registry/$project/$repository:$TAG
    $LATEST &&  {
        docker tag $localReg/$repository:$TAG $registry/$project/$repository:latest
        echo "Uploading image $registry/$project/$repository:latest"
        docker push $registry/$project/$repository:latest
    }
}
