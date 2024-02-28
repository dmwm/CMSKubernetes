#!/bin/bash

### This script is to be used for building a MariaDB docker imagge based on pypi
### It depends on a single parameter MDB_TAG


help(){
    echo -e $*
    cat <<EOF

The MariaDB docker build script for Docker image creation based on pypi:

Usage: mariadb-docker-build.sh -v <mariadb_tag>

    -t <mariadb_tag>                The MariaDB version/tag to be used for the Docker image creation
    -p <push_image>                 Push the image to registry.cern.ch
    -l <latest_tag_toregistry>      Push the curernt tag also as latest to registry.cern.ch

Example: ./mariadb-docker-build.sh -v 2.2.0.2

EOF
}

usage(){
    help $*
    exit 1
}

MDB_TAG=None
PUSH=false
LATEST=false

### Argument parsing:
while getopts ":t:hpl" opt; do
    case ${opt} in
        t) MDB_TAG=$OPTARG ;;
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


# NOTE: NO MDB_TAG validation is done in the current script. The proper tag
#       to be used should be taken from: https://mariadb.org/mariadb/all-releases/
dockerOpts=" --network host --progress=plain --build-arg MDB_TAG=$MDB_TAG "

docker build $dockerOpts -t local/mariadb:$MDB_TAG -t local/mariadb:latest  .

$PUSH && {
    # For security reasons we check if the login name and the current user match.
    # If they do not, abort the execution and push nothing to registry.cern.ch.
    loginUser=`logname`
    currUser=`id -un`
    registry=registry.cern.ch
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
    docker tag local/mariadb:$MDB_TAG $registry/cmsweb/mariadb:$MDB_TAG
    echo "Uploading image $registry/cmsweb/mariadb:$MDB_TAG"
    docker push $registry/cmsweb/mariadb:$MDB_TAG
    $LATEST &&  {
        docker tag local/mariadb:$MDB_TAG $registry/cmsweb/mariadb:latest
        echo "Uploading image $registry/cmsweb/mariadb:latest"
        docker push $registry/cmsweb/mariadb:latest
    }
}
