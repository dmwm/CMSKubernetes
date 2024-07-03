#!/bin/bash
set -e
# Build help script for cmsmon-spark docker image

mkdir -p "$WDIR"/logs

# -- Get amtool
curl -ksLO https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz
tar xfz alertmanager-0.24.0.linux-amd64.tar.gz && mv alertmanager-0.24.0.linux-amd64/amtool "$WDIR/" && rm -rf alertmanager-0.24.0.linux-amd64*

# -- If $CMSSPARK_TAG docker arg is defined, checkout to its CMSSpark git tag, else use dmwm master branch.
if [ -z "$CMSSPARK_TAG" ]; then
    git clone https://github.com/dmwm/CMSSpark.git
else
    git clone https://github.com/dmwm/CMSSpark.git && cd CMSSpark && git checkout tags/"$CMSSPARK_TAG" -b build && cd ..
fi

# -- If $CMSMON_TAG docker arg is defined, checkout to its CMSMonitoring git tag, else use dmwm master branch.
if [ -z "$CMSMON_TAG" ]; then
    git clone https://github.com/dmwm/CMSMonitoring.git
else
    git clone https://github.com/dmwm/CMSMonitoring.git && cd CMSMonitoring && git checkout tags/"$CMSMON_TAG" -b build && cd ..
fi

# -- Create zip file of only CMSMonitoring/src/python/CMSMonitoring to provide to Spark "--py-files"
zip -r CMSMonitoring.zip CMSMonitoring/src/python/CMSMonitoring/*

echo "Info: CMSSPARK_TAG=${CMSSPARK_TAG} , CMSMON_TAG=${CMSMON_TAG}, HADOOP_CONF_DIR=${HADOOP_CONF_DIR}, PATH=${PATH}, PYTHONPATH=${PYTHONPATH}, PYSPARK_PYTHON=${PYSPARK_PYTHON}, PYSPARK_DRIVER_PYTHON=${PYSPARK_DRIVER_PYTHON}"
