FROM cern/cc7-base:20210201-1.x86_64
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

# set working directory
ENV WDIR=/data
WORKDIR $WDIR
ENV PATH="${PATH}:${WDIR}"

# set required env vars
ENV VIRTUAL_ENV "/venv"
ENV HADOOP_CONF_DIR=/etc/hadoop/conf

# add required files
ADD hadoop.repo /etc/yum.repos.d/hadoop.repo
ADD hadoop-mapreduce-client-core-2.6.0-cdh5.7.6.jar $WDIR
ADD cronjobs.txt $WDIR

# install required packages
RUN yum install -y cern-hadoop-config spark-bin-2.3.0 hadoop-bin-2.7.5 java-1.8.0-openjdk-devel gcc git python3 && yum clean all 

# setup hadoop
RUN hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix 

# use python3
RUN python3 -m venv $VIRTUAL_ENV && source $VIRTUAL_ENV/bin/activate && pip install pandas pyspark click && git clone https://github.com/dmwm/CMSSpark.git

# set PATH
ENV PATH "$VIRTUAL_ENV/bin:/usr/hdp/hadoop-2.7.5/bin:/usr/hdp/spark/bin:$PATH"

# Setup cron
CMD ["crond", "-n", "-s", "&"]
RUN chmod 755 $WDIR/cronjobs.txt && crontab $WDIR/cronjobs.txt
