FROM cern/cc7-base:20200504-1.x86_64
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ADD hadoop.repo /etc/yum.repos.d/hadoop.repo

# hadoop related RPMs
RUN yum install -y cern-hadoop-config spark-bin-3.0 hadoop-bin-2.7.5 java-1.8.0-openjdk-devel gcc git
RUN yum clean all

# setup proper environment
ENV PATH $PATH:/usr/hdp/hadoop-2.7.5/bin:/usr/hdp/spark3/bin
RUN hadoop-set-default-conf.sh analytix
RUN source hadoop-setconf.sh analytix

# setup necessary environment
ENV WDIR=/data
ENV PATH="${PATH}:${WDIR}"

# install rumble jar
WORKDIR $WDIR
RUN wget -nv -O spark-rumble.jar https://github.com/RumbleDB/rumble/releases/download/v1.9.0/spark-rumble-1.9.0.jar

# Setup cron
CMD ["crond", "-n", "&"]
ADD cronjobs.txt $WDIR
RUN crontab $WDIR/cronjobs.txt

# add files
ADD run.sh $WDIR
ADD daemon.sh $WDIR
RUN chmod 755 $WDIR/daemon.sh
RUN chmod 755 $WDIR/run.sh
# Trick to run first run.sh script
RUN echo " Exception in thread " >> $WDIR/server.log
