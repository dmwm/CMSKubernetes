FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN yum install -y cern-hadoop-config spark-bin-2.3.0 hadoop-bin-2.7.5 hbase-bin-1.2.6 sqoop-bin-1.4

ENV WDIR=/data
ADD scripts $WDIR/sqoop
ADD queries $WDIR/sqoop/queries
RUN hadoop-set-default-conf.sh analytix
RUN source hadoop-setconf.sh analytix
WORKDIR $WDIR/sqoop
