#!/bin/bash
# build_monitoring.sh: script to build docker images for cmsmonitoring k8s services

# This script
#   - build and push docker images to ONLY Cern registry
#   - uses current git commit hash as docker tag
#   - provides "-stable" argument to build docker tags with "-stable" postfix,
#       which sets retention of image as 360 days with immutability,
#     If "-stable" arg is not provided, does not apply "-stable" postfix to the image as default,
#       which has 180 days of retention and NO immutability.

# define help
if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
    echo "Usage: build.sh <pkgs> <-stable | -not-stable>[optional, default: -not-stable]"
    echo "Examples:"
    echo "  # build image for one cmsmonitoring service with -not-stable flag as default"
    echo "  ./build_monitoring.sh \"sqoop\""
    echo "  # build images for multiple cmsmonitoring services with -stable flag"
    echo "  ./build_monitoring.sh \"sqoop karma\" -stable"
    exit 1
fi

echo "This script will set the Docker image tag as the current commit hash"

# DOCKER_TAG: Add git commit short hash as docker image tag
if ! DOCKER_TAG=$(git rev-parse --short HEAD); then
    echo "'git rev-parse --short HEAD' failed. Exiting!"
    exit 1
fi

# We can add building all cmsmonitoring docker images.
#monitoring_pkgs="cmsmon cmsmon-alerts cmsmon-intelligence cmsweb-monit condor-cpu-eff jobber karma log-clustering monitor nats-nsc nats-sub rumble sqoop vmbackup-utility udp-server"

# If it's empty, help conditions catch it
PKGS=${1:-}
IS_STABLE=${2:-not-stable}
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
  - To give appropriate docker TAG, please git checkout to the desired commit:
  - If you want to create docker images with the latest commit:
      $ git remote -v | grep upstream # should be 'https://github.com/dmwm/CMSKubernetes.git
      $ git fetch --all
      $ git pull --rebase upstream master
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
echo "To remove all images please use this command"
echo "  $ docker rmi \$(docker images -qf \"dangling=true\")"
echo "  $ docker images | awk '{print \"docker rmi -f \"$3\"\"}' | /bin/sh"

