FROM registry.cern.ch/cmsweb/cmsweb:20211201-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN yum -y update
RUN yum install -y cern-hadoop-config spark-bin-2.3.0 hadoop-bin-2.7.5 hbase-bin-1.2.6 sqoop-bin-1.4
RUN yum install -y java-1.8.0-openjdk-devel
RUN yum clean all && rm -rf /var/cache/yum

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
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/client_golang/prometheus/promhttp
WORKDIR $WDIR/CMSMonitoring/src/go/MONIT
RUN go build monit.go && go build hdfs_exporter.go && cp monit hdfs_exporter $WDIR
WORKDIR $WDIR

# get amtool
RUN curl -ksLO https://github.com/prometheus/alertmanager/releases/download/v0.20.0/alertmanager-0.20.0.linux-amd64.tar.gz
RUN tar xfz alertmanager-0.20.0.linux-amd64.tar.gz && mv alertmanager-0.20.0.linux-amd64/amtool $WDIR/ && rm -rf alertmanager-0.20.0.linux-amd64*
