#!/bin/sh
# Builds and push cmsmon-hadoop-base image based on analytix cluster and spark version
# Usage: build.sh <ANALYTIX_VERSION>(2|3)

set -e

if [ $# -ne 1 ] || ! { [ "$1" -eq 2 ] || [ "$1" -eq 3 ]; }; then
    echo "No arguments supplied or not desired. Analytix cluster version should be either 2 or 3"
fi

echo "!! Reminder, do not forget to clean local images with: docker system prune -f -a"

CC7_BASE_VERSION=20220401-1
DOCKER_REGISTRY=registry.cern.ch/cmsmonitoring

# Get argument, should be 2 or 3
ANALYTIX_VERSION="$1"
echo Image will be built: "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"

if [ "$ANALYTIX_VERSION" -eq 3 ]; then
    hadoop_v=3.2
    spark_v=3.2
    spark_major_v=spark3
    image_tag="${CC7_BASE_VERSION}-${spark_major_v}"
elif [ "$ANALYTIX_VERSION" -eq 2 ]; then
    hadoop_v=2.7
    spark_v=2.4
    spark_major_v=spark2
    image_tag="${CC7_BASE_VERSION}-${spark_major_v}"
fi

echo Image will be built: "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"

# build
docker build \
    --build-arg CC7_BASE_VERSION="$CC7_BASE_VERSION" \
    --build-arg HADOOP_VERSION="$hadoop_v" \
    --build-arg SPARK_VERSION="$spark_v" \
    --build-arg SPARK_MAJOR_VERSION="$spark_major_v" \
    -t "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}" .

echo Build finished

# push
docker push "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"

echo Push finished : "${DOCKER_REGISTRY}/cmsmon-hadoop-base:${image_tag}"
