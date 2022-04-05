FROM registry.cern.ch/cmsweb/oracle:21_5 as oracle
#FROM cmssw/oracle:21_1 as oracle
FROM golang:latest as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# get oracle for our build
COPY --from=oracle /usr/lib/oracle /usr/lib/oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle

# update apt
#RUN apt-get update && apt-get -y install unzip

# start the setup
ENV WDIR=/data
RUN mkdir -p $WDIR
WORKDIR ${WDIR}
ADD oci8.pc $WDIR/oci8.pc
ENV PKG_CONFIG_PATH=$WDIR

# build dbs2go with specific tag
ENV TAG=v00.05.05
WORKDIR $GOPATH/src/github.com/vkuznet
RUN git clone https://github.com/vkuznet/dbs2go
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go

# example how to checkout specific branch
# RUN git checkout --track origin/api-struct && \
RUN git checkout tags/$TAG -b build && \
    sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go && \
    make && cp -r dbs2go static $WDIR

# for gibc library we will use debian:stretch
FROM debian:stable-slim
RUN apt-get update && apt-get -y install libaio1 procps && mkdir -p /data
COPY --from=builder /data /data
COPY --from=oracle /usr/lib/oracle /usr/lib/oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle

# remove shell from the image
RUN apt-get -y --allow-remove-essential remove bash --purge
RUN rm /bin/dash /bin/sh

# run the service
ENV PATH="/data/gopath/bin:/data:${PATH}"
WORKDIR /data
