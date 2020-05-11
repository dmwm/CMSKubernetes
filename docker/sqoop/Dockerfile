FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN yum install -y cern-hadoop-config spark-bin-2.3.0 hadoop-bin-2.7.5 hbase-bin-1.2.6 sqoop-bin-1.4
RUN yum install -y java-1.8.0-openjdk-devel

ENV WDIR=/data
ADD scripts $WDIR/sqoop
ADD queries $WDIR/sqoop/queries
ADD run.sh $WDIR/sqoop
ADD daemon.sh $WDIR/sqoop
ADD cronjobs.txt $WDIR/sqoop
RUN hadoop-set-default-conf.sh analytix
RUN source hadoop-setconf.sh analytix
ENV PATH $PATH:/usr/hdp/hadoop/bin:/usr/hdp/sqoop/bin
RUN mkdir -p $WDIR/sqoop/log
WORKDIR $WDIR/sqoop
RUN ln -s /etc/cmsdb/cmsr_cstring
RUN ln -s /etc/cmsdb/lcgr_cstring
RUN crontab cronjobs.txt

# cms-monitoring es-sizes
WORKDIR $WDIR
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${PATH}:${GOROOT}/bin:${WDIR}"
ENV PYTHONPATH="${WDIR}/CMSMonitoring/src/python"
RUN git clone https://github.com/dmwm/CMSMonitoring.git
RUN go get github.com/go-stomp/stomp
WORKDIR $WDIR/CMSMonitoring/src/go/MONIT
RUN go build monit.go
RUN cp monit $WDIR
WORKDIR $WDIR
