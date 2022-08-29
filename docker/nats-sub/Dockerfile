FROM golang:1
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV CMSMON_TAG=go-0.0.0
ENV WDIR=/data
WORKDIR $WDIR
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/CMSMonitoring/${CMSMON_TAG}/src/go/NATS/nats-sub.go && \
    go mod init github.com/CMSMonitoring/nats-sub && \
    go mod tidy && \
    go build nats-sub.go
