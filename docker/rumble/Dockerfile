FROM cern/cc7-base:20210601-1.x86_64
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ENV WDIR=/data
RUN mkdir -p $WDIR/queries

ADD hadoop.repo /etc/yum.repos.d/hadoop.repo
ADD run.sh $WDIR/run.sh

# Uses oracle java jvm
RUN yum install -y cern-hadoop-config spark-bin-3.0 hadoop-bin-2.7.5 git git-core && \
    yum clean all && \
    rm -rf /var/cache/yum

ENV PATH $PATH:/usr/hdp/hadoop-2.7.5/bin:/usr/hdp/spark3/bin

WORKDIR $WDIR
RUN curl -k -L -O https://golang.org/dl/go1.16.5.linux-amd64.tar.gz && \
    tar xfz go1.16.5.linux-amd64.tar.gz && \
    mkdir $WDIR/gopath && \
    rm -rf go1.16.5.linux-amd64.tar.gz && \
    hadoop-set-default-conf.sh analytix && \
    source hadoop-setconf.sh analytix && \
    chmod +x $WDIR/run.sh

# $WDIR/go/bin/go env -w GO111MODULE=off && \

ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH $PATH:$GOROOT/bin:$WDIR

RUN git clone https://github.com/mrceyhun/rumble_jar.git && \
    cp rumble_jar/spark-rumble-cmsmonit.jar $WDIR/spark-rumble.jar && \
    rm -rf rumble_jar && \
    git clone https://github.com/mrceyhun/CMSMonitoring.git && \
    cp -R CMSMonitoring/src/go/Rumble/* $WDIR && \
    rm -rf CMSMonitoring && \
    go build rumble_server.go && \
    chmod +x $WDIR/rumble_server

ENV RUMBLE_JAR_FILE=$WDIR/spark-rumble.jar
