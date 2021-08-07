FROM cern/cc7-base:20210715-1.x86_64
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# set working directory
ENV WDIR=/data
WORKDIR $WDIR
ENV PATH="${PATH}:${WDIR}"

# set required env vars
ENV VIRTUAL_ENV "/venv"
ENV HADOOP_CONF_DIR=/etc/hadoop/conf
ENV PATH "$VIRTUAL_ENV/bin:/usr/hdp/hadoop-2.7.5/bin:/usr/hdp/spark-2.4/bin:$PATH"
ENV PYSPARK_PYTHON=/usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON=$VIRTUAL_ENV/bin/python

# add required files
ADD hadoop.repo /etc/yum.repos.d/hadoop.repo
ADD hadoop-mapreduce-client-core-2.6.0-cdh5.7.6.jar $WDIR
ADD cronjobs.txt $WDIR

# oracle java is included as spark dependency
RUN yum install -y cern-hadoop-config spark-bin-2.4 hadoop-bin-2.7.5 git python3 && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    hadoop-set-default-conf.sh analytix && \
    source hadoop-setconf.sh analytix && \
    python3 -m venv $VIRTUAL_ENV && \
    source $VIRTUAL_ENV/bin/activate && \
    pip install pandas pyspark click && \
    git clone https://github.com/dmwm/CMSSpark.git

# Setup cron
CMD ["crond", "-n", "-s", "&"]
RUN chmod 755 $WDIR/cronjobs.txt && crontab $WDIR/cronjobs.txt
