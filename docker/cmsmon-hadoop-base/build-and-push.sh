#!/bin/sh
# Builds and push cmsmon-hadoop-base image
# Usage: build-and-push.sh
# Examples:
#   - ./build-and-push.sh

set -e

if [ $# -ne 0 ]; then
    echo "No arguments needed"
    exit 1
fi

echo "!! Reminder, do not forget to clean local images with: docker system prune -f -a"

CURRENT_DATE=$(date +"%Y%m%d")
DOCKER_REGISTRY=registry.cern.ch/cmsmonitoring

# Build
image_tag="spark3-${CURRENT_DATE}"
echo "Building ${image_tag}"
docker build --user root -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}" -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:latest" -f Dockerfile-spark3 .
echo Build finished: "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
# Push
docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:latest"
echo Push finished : "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
