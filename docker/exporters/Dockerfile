FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV GOPATH=/data/gopath
RUN mkdir -p $GOPATH
RUN mkdir /build

ARG NODEEXP_VER=1.9.1
ARG APACHEEXP_VER=1.0.10
ARG MONGOEXP_EVR=1.0.0

# download node exporter
RUN curl -ksLO https://github.com/prometheus/node_exporter/releases/download/v${NODEEXP_VER}/node_exporter-${NODEEXP_VER}.linux-amd64.tar.gz && \
    tar xfz node_exporter-${NODEEXP_VER}.linux-amd64.tar.gz && \
    cp node_exporter*/node_exporter /build 

# build cmsweb exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
WORKDIR /data
RUN git clone https://github.com/dmwm/cmsweb-exporters.git
ARG CGO_ENABLED=0
RUN cd cmsweb-exporters && \
    go build -o /build/das2go_exporter -ldflags="-s -w -extldflags -static" das2go_exporter.go && \
    go build -o /build/reqmgr_exporter -ldflags="-s -w -extldflags -static" reqmgr_exporter.go && \
    go build -o /build/wmcore_exporter -ldflags="-s -w -extldflags -static" wmcore_exporter.go && \
    go build -o /build/http_exporter -ldflags="-s -w -extldflags -static" http_exporter.go && \
    go build -o /build/process_exporter -ldflags="-s -w -extldflags -static" process_exporter.go && \
    go build -o /build/cpy_exporter -ldflags="-s -w -extldflags -static" cpy_exporter.go && \
    go build -o /build/cmsweb-ping -ldflags="-s -w -extldflags -static" cmsweb-ping.go && \
    cp process_monitor.sh /build

# Adding apache exporter
#        https://github.com/Lusitaniae/apache_exporter/releases/download/v1.0.10/apache_exporter-1.0.10.linux-amd64.tar.gz
RUN wget https://github.com/Lusitaniae/apache_exporter/releases/download/v${APACHEEXP_VER}/apache_exporter-${APACHEEXP_VER}.linux-amd64.tar.gz && \
  tar -xvzf apache_exporter-${APACHEEXP_VER}.linux-amd64.tar.gz --directory /data/gopath && \
  cp /data/gopath/apache_exporter-${APACHEEXP_VER}.linux-amd64/apache_exporter /build

# build mongo exporter
# TODO: consider using an actively developed exporter, such as
#   https://github.com/percona/mongodb_exporter
#   dcu/mongo_exporter seems stale since 2016
#   related ticket: https://its.cern.ch/jira/projects/CMSMONIT/issues/CMSMONIT-650
WORKDIR /tmp
RUN curl -ksLO https://github.com/dcu/mongodb_exporter/releases/download/v${MONGOEXP_EVR}/mongodb_exporter-linux-amd64
RUN cp mongodb_exporter-linux-amd64 /build/mongodb_exporter

#FROM alpine
FROM debian:12-slim
RUN apt-get update && apt-get install -y procps

RUN mkdir -p /data
# https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/
#FROM gcr.io/distroless/static AS final
COPY --from=go-builder /build/* /data/
#RUN sed -i -e "s,bash,sh,g" -e "s,print \$2,print \$1,g" /data/process_monitor.sh
ENV PATH $PATH:/data

# ADD run.sh /data/run.sh
# ADD probe.sh /data/probe.sh
# RUN ln -s /bin/sh /bin/bash
