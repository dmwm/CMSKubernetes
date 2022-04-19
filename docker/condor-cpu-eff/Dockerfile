FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:20220401-1-spark3
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# set working directory
ENV WDIR=/data
WORKDIR $WDIR

# For python click ASCII problem: https://click.palletsprojects.com/en/8.1.x/unicode-support/
ENV LC_ALL=en_US.utf-8 LANG=en_US.utf-8
ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH="${PATH}:${WDIR}:/usr/hdp/hadoop/bin/hadoop:/usr/hdp/spark3/bin:/usr/hdp/sqoop/bin:${WDIR}/CMSSpark/bin"
ENV PYTHONPATH "${PYTHONPATH}:${WDIR}/CMSSpark/src/python"
ENV PYSPARK_PYTHON=/usr/bin/python3 PYSPARK_DRIVER_PYTHON=/usr/bin/python3

RUN yum remove -y hbase-bin-2.3 && \
    yum update -y && yum install -y python3 && yum clean all && rm -rf /var/cache/yum && \
    python3 -m pip install --upgrade pip && pip3 install --no-cache-dir pandas pyspark click && \
    rm -f /usr/bin/python && ln -s /usr/bin/python3.6 /usr/bin/python && \
    git clone https://github.com/dmwm/CMSSpark.git && \
    hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 3.2 spark3

WORKDIR $WDIR
# Run crond
CMD ["crond", "-n", "-s", "&"]
