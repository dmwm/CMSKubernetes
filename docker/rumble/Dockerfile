FROM cern/cc7-base:20200504-1.x86_64
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# setup necessary environment
ENV WDIR=/data
ENV PATH="${PATH}:${WDIR}"

ADD hadoop.repo /etc/yum.repos.d/hadoop.repo

# install hadoop related RPMs and rumble jar
WORKDIR $WDIR
RUN yum install -y cern-hadoop-config spark-bin-3.0 hadoop-bin-2.7.5 java-1.8.0-openjdk-devel gcc git && yum clean all && wget -nv -O spark-rumble.jar https://github.com/RumbleDB/rumble/releases/download/v1.9.0/spark-rumble-1.9.0.jar

# setup proper environment
ENV PATH $PATH:/usr/hdp/hadoop-2.7.5/bin:/usr/hdp/spark3/bin
RUN hadoop-set-default-conf.sh analytix && source hadoop-setconf.sh analytix

# Setup cron
CMD ["crond", "-n", "-s", "&"]
ADD cronjobs.txt $WDIR

# add required scripts
ADD daemon.sh $WDIR
RUN git clone https://github.com/dmwm/CMSMonitoring.git && cp CMSMonitoring/scripts/run_rumble.sh $WDIR && chmod 755 $WDIR/daemon.sh && chmod 755 $WDIR/run_rumble.sh && crontab $WDIR/cronjobs.txt
