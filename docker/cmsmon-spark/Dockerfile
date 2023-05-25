# cmsmon-spark
FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:spark3-latest
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# tag to use
ARG CMSSPARK_TAG
ARG CMSMON_TAG

ENV WDIR=/data
WORKDIR $WDIR
ADD install.sh $WDIR/install.sh

ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH="${PATH}:${WDIR}/CMSSpark/bin"
ENV PYTHONPATH "${PYTHONPATH}:${WDIR}:${WDIR}/CMSSpark/src/python:${WDIR}/CMSMonitoring/src/python"

# How to find: source LCG102 hadoop setup, which python, ln -ls python, voila!
ENV PYSPARK_PYTHON=/cvmfs/sft.cern.ch/lcg/releases/Python/3.9.12-9a1bc/x86_64-centos7-gcc8-opt/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3
ENV LC_ALL=en_US.utf-8 LANG=en_US.utf-8

RUN CMSSPARK_TAG="$CMSSPARK_TAG" CMSMON_TAG="$CMSMON_TAG" ./install.sh && \
    hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 3.2 spark3

# Run crond
CMD ["crond", "-n", "-s", "&"]
