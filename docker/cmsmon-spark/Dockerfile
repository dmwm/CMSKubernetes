# cmsmon-spark
FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:spark3-el9-20240708
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

RUN CMSSPARK_TAG="$CMSSPARK_TAG" CMSMON_TAG="$CMSMON_TAG" ./install.sh && \
    hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 3.3 spark3

# Run crond
CMD ["crond", "-n", "-s", "&"]
