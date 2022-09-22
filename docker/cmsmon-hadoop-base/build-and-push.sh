#!/bin/sh
# Builds and push cmsmon-hadoop-base image based on spark version
# Usage: build.sh <ANALYTIX_VERSION>(2|3) <PY_VERSION>(optional, required for spark3)
# Examples:
#   - build spark3
#     ./build.sh 3 3.9.12
#   - build spark3
#     ./build.sh 2

set -e

if [ $# -eq 0 ] || ! { [ "$1" -eq 2 ] || [ "$1" -eq 3 ]; }; then
    echo "No arguments supplied or not desired. Analytix cluster version should be either 2 or 3"
    exit 1
fi

if [ "$1" -eq 3 ] && [ $# -ne 2 ]; then
    echo "You are building spark3, please provide PY_VERSION as second argument, i.e 3.9.12"
    exit 1
fi

echo "!! Reminder, do not forget to clean local images with: docker system prune -f -a"

CURRENT_DATE=$(date +"%Y%m%d")
DOCKER_REGISTRY=registry.cern.ch/cmsmonitoring

# Get argument, should be 2 or 3
ANALYTIX_VERSION="$1"
PY_VERSION="$2"

# Build
if [ "$ANALYTIX_VERSION" -eq 3 ]; then
    image_tag="spark3-${CURRENT_DATE}"
    echo "Building ${image_tag} with PY_VERSION:${PY_VERSION}"
    docker build --build-arg PY_VERSION="$PY_VERSION" -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}" -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:spark3-latest" -f Dockerfile-spark3 .
    echo Build finished: "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
    #
    docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
    docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:spark3-latest"
    echo Push finished : "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
elif [ "$ANALYTIX_VERSION" -eq 2 ]; then
    image_tag="spark2-${CURRENT_DATE}"
    echo "Building ${image_tag}"
    docker build -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}" -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:spark2-latest" -f Dockerfile-spark2 .
    echo Build finished: "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
    #
    docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
    docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:spark2-latest"
    echo Push finished : "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
fi
