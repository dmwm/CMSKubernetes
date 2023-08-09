FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# tag to use
ENV CMSMON_TAG=go-0.0.0

ENV WDIR=/data
WORKDIR $WDIR
ENV PATH $PATH:$WDIR:$WDIR/CMSMonitoring/scripts
RUN mkdir gopath
ENV GOPATH $WDIR/gopath

RUN git clone https://github.com/dmwm/CMSMonitoring.git
ARG CGO_ENABLED=0
WORKDIR $WDIR/CMSMonitoring
RUN git checkout tags/$CMSMON_TAG -b build && cd src/go/intelligence && make

FROM alpine:3.17
RUN mkdir /data
COPY --from=go-builder /data/CMSMonitoring/src/go/intelligence/intelligence /data
ENV PATH $PATH:/data
