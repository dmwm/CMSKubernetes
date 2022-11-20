# cmsmon-spark
FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:spark3-latest
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# tag to use
ARG CMSSPARK_TAG=0.0.0
ENV WDIR=/data
WORKDIR $WDIR

ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH="${PATH}:/usr/hdp/hadoop/bin/hadoop:/usr/hdp/spark3/bin:/usr/hdp/sqoop/bin:${WDIR}/CMSSpark/bin"
ENV PYTHONPATH "${PYTHONPATH}:${WDIR}:${WDIR}/CMSSpark/src/python:${WDIR}/CMSMonitoring/src/python"

# How to find: source LCG102 hadoop setup, which python, ln -ls python, voila!
ENV PYSPARK_PYTHON=/cvmfs/sft.cern.ch/lcg/releases/Python/3.9.12-9a1bc/x86_64-centos7-gcc8-opt/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3
ENV LC_ALL=en_US.utf-8 LANG=en_US.utf-8

RUN mkdir -p $WDIR/logs && \
    git clone https://github.com/dmwm/CMSSpark.git && cd CMSSpark && git checkout tags/$CMSSPARK_TAG -b build && cd .. && \
    git clone https://github.com/dmwm/CMSMonitoring.git && \
    zip -r CMSMonitoring.zip CMSMonitoring/src/python/CMSMonitoring/* && \
    pip install --no-cache-dir stomp.py==7.0.0 click pyspark pandas numpy schema seaborn matplotlib plotly && \
    hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 3.2 spark3

# Run crond
CMD ["crond", "-n", "-s", "&"]
