#!/bin/bash

### This script is to be used for building a Coucdb docker imagge based on pypi
### It depends on a single parameter WMA_TAG, which is to be passed to the basic
### Coucdb deployment script install.sh at build time through `docker --build-arg`


help(){
    echo -e $*
    cat <<EOF

The Coucdb docker build script for Docker image creation based on pypi:

Usage: coucdb-docker-build.sh -v <coucdb_tag>

    -t <couch_tag>                  The Couchdb (upstream tag) tag to base this this image on
    -u <coucdb_user>                The Couchdb user to be used for the Docker image creation
    -p <password>                   The Couchdb user to be used for the Docker image creation
    -h <help>                       Provides this help

Example: ./coucdb-docker-build.sh -u FIXME_USER -p FIXME_PWD

EOF
}

usage(){
    help $*
    exit 1
}

TAG=3.3.2
COUCH_USER=FIXME_USER
COUCH_PASS=FIXME_PWD

### Argument parsing:
while getopts ":t:u:p:h" opt; do
    case ${opt} in
        t) TAG=$OPTARG ;;
        u) COUCH_USER=$OPTARG ;;
        p) COUCH_PASS=$OPTARG ;;
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

docker build $dockerOpts -t local/couchdb:$TAG -t local/couchdb:latest  .
