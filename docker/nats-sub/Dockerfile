FROM golang:1.17.0-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/CMSMonitoring/master/src/go/NATS/nats-sub.go
RUN go get github.com/nats-io/nats.go
RUN go build nats-sub.go
