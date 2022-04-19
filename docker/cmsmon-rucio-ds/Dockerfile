FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:20220401-1-spark3

ENV WDIR=/data
WORKDIR $WDIR

ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH="${PATH}:/usr/hdp/hadoop/bin/hadoop:/usr/hdp/spark3/bin:/usr/hdp/sqoop/bin:${WDIR}/CMSSpark/bin"
# CMSMonitoring folder is in WDIR
ENV PYTHONPATH "${PYTHONPATH}:${WDIR}:${WDIR}/CMSSpark/src/python"

ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3

# Steps:
#   - Remove hbase, not needed
#   - Install python3
#   - Install python libs and specifically stomp.py==7.0.0 which is latest working version with StompAMQ7
#   - Install and create stomp.py v7.0.0 zip file to send to Spark workers,
#         because Spark nodes have old version of it (v3 or v4)
#   - Clone only src/python/CMSMonitoring folder of CMSMoinitoring repo using svn and zip it,
#         zip file will be used to send specific CMSMonitoring folder to Spark workers with '--py-files'.
#   - Clone CMSSpark repo which includes Spark job and bash script to run both Spark job and Sqoop imports
RUN yum remove -y hbase-bin-2.3 && \
    yum update -y && \
    yum install -y svn python3 && \
    python3 -m pip install --upgrade pip && \
    pip3 install --no-cache-dir pandas click pyspark stomp.py==7.0.0 && \
    pip3 install --no-cache-dir -t stomp-v700 https://github.com/jasonrbriggs/stomp.py/archive/refs/tags/v7.0.0.zip && \
    cd stomp-v700 && \
    zip -r ../stomp-v700.zip . && \
    cd .. && \
    rm -rf stomp-v700 && \
    svn export https://github.com/dmwm/CMSMonitoring.git/branches/master/src/python/CMSMonitoring && \
    zip -r CMSMonitoring.zip CMSMonitoring/* && \
    git clone https://github.com/dmwm/CMSSpark.git && \
    yum clean all &&  rm -rf /var/cache/yum && \
    rm -f /usr/bin/python && ln -s /usr/bin/python3.6 /usr/bin/python && \
    hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 3.2 spark3

WORKDIR $WDIR

# Run crond
CMD ["crond", "-n", "-s", "&"]
