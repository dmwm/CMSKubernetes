FROM python:3.9 as builder
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# tag to use
ENV CMSMON_TAG=0.0.0
ENV WDIR=/data
WORKDIR $WDIR

# Create zip files of stomp.py and CMSMonitoring modules to submit Spark workers
RUN apt-get update -y && \
    apt-get install -y zip subversion && \
#   Install python stomp.py==7.0.0 module which is the latest working version with StompAMQ7
    pip install --no-cache-dir -t stomp-v700 https://github.com/jasonrbriggs/stomp.py/archive/refs/tags/v7.0.0.zip && \
#   Create zip file to send to Spark workers, because workers have old version of it (v3 or v4)
    cd stomp-v700 && \
    zip -r ../stomp-v700.zip . && \
    cd .. && \
    rm -rf stomp-v700 && \
#   Clone only src/python/CMSMonitoring folder of CMSMoinitoring repo using svn and zip it,
#   zip file will be used to send specific CMSMonitoring folder to Spark workers with '--py-files'.
    svn export https://github.com/dmwm/CMSMonitoring.git/branches/master/src/python/CMSMonitoring && \
    zip -r CMSMonitoring.zip CMSMonitoring/* && \
    git clone https://github.com/dmwm/CMSSpark.git && cd CMSSpark && git checkout tags/$CMSMON_TAG -b build && cd ..

FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:spark3-20220606
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ENV WDIR=/data
ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH="${PATH}:/usr/hdp/hadoop/bin/hadoop:/usr/hdp/spark3/bin:/usr/hdp/sqoop/bin:${WDIR}/CMSSpark/bin"

# CMSMonitoring folder is in WDIR
ENV PYTHONPATH "${PYTHONPATH}:${WDIR}:${WDIR}/CMSSpark/src/python"

# LCG102 uses this cvmfs python
ENV PYSPARK_PYTHON=/cvmfs/sft.cern.ch/lcg/releases/Python/3.9.6-b0f98/x86_64-centos7-gcc8-opt/bin/python3

# Local
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python

WORKDIR $WDIR

COPY --from=builder /data $WDIR

RUN mkdir -p $WDIR/logs && \
    pip install --no-cache-dir pandas click pyspark stomp.py==7.0.0 && \
    hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 3.2 spark3

# Run crond
CMD ["crond", "-n", "-s", "&"]
