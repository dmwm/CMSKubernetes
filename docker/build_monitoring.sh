#!/bin/bash
##H Usage:  <pkgs> <tag> <-stable|-not-stable>[optional, default: -not-stable]
##H
##H Arguments:
##H   1st=PKGS       : image name(s) [required]
##H   2st=DOCKER_TAG : tag           [required]
##H   3st=IS_STABLE  : is stable     [optional]
##H
##H Explanation
##H   - build and push docker images to ONLY Cern registry
##H   - provides "-stable" argument to build docker tags with "-stable" postfix,
##H       which sets retention of image as 360 days with immutability,
##H     If "-stable" arg is not provided, does not apply "-stable" postfix to the image as default,
##H       which has 180 days of retention and NO immutability.
##H
##H Examples:
##H   > build not-stable(default) image
##H       $ build_monitoring.sh cmsmon-hadoop-base 20220202-01
##H   > build stable image
##H       $ build_monitoring.sh cmsmon-hadoop-base 20220202-01 -stable
##H

# help definition
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' <$0
    exit 1
fi

# If it's empty, help conditions catch it
PKGS=${1:-}
DOCKER_TAG=${2:-}
IS_STABLE=${3:-not-stable}
REGISTRY=registry.cern.ch/cmsmonitoring
REPO=cmsmonitoring

# Set -stable if provided in input args
if [ "$IS_STABLE" = "-stable" ]; then
    DOCKER_TAG="${DOCKER_TAG}-stable"
fi

# Interactive Y\N prompt message
read -r -d '' prompt_msg <<EOM
Please read carefully!
  - To not conflict docker images, please prune images:
      $ docker system prune -f -a
      $ docker rmi $(docker images -qf "dangling=true")
  - ### Docker images will be build with below settings: ###
    #    Packages to build  : $PKGS
    #    TAG will be used   : $DOCKER_TAG
    #    Is stable          : $IS_STABLE
    #    Registry           : $REGISTRY
    #    Repo               : $REPO
    ########################################################
  - I know what I'm doing... [Y|y]
EOM

# Interactive Y\N prompt to continue, because of the critical nature of the script
read -p "$prompt_msg" -n 1 -r
echo #
if ! [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Exiting..."
    exit 1
fi
echo "Alright, continuing to build docker images..."
echo #

for pkg in $PKGS; do
    echo "###    building $REGISTRY/$pkg:$DOCKER_TAG"
    if ! docker build -t $REPO/"$pkg" -t $REPO/"$pkg":"$DOCKER_TAG" "$pkg"; then
        echo "Docker build NOT successful, exiting!"
        exit 1
    fi
    if ! docker tag $REPO/"$pkg":"$DOCKER_TAG" $REGISTRY/"$pkg":"$DOCKER_TAG"; then
        echo "Docker tagging is NOT successful, exiting!"
        docker rmi $REGISTRY/"$pkg":"$DOCKER_TAG"
        exit 1
    fi
    echo "###    existing images"
    docker images

    echo "###    pushing to CERN registry only"
    if ! docker push $REGISTRY/"$pkg":"$DOCKER_TAG"; then
        echo "Docker push is NOT successful, exiting!"
        docker rmi $REGISTRY/"$pkg":"$DOCKER_TAG"
        exit 1
    fi

    echo "###    removing pushed docker image from local"
    docker rmi $REGISTRY/"$pkg":"$DOCKER_TAG"
done

echo
