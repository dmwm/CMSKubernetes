FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
ENV PATH $PATH:$WDIR:$WDIR/CMSMonitoring/scripts
RUN mkdir gopath
ENV GOPATH $WDIR/gopath
RUN git clone https://github.com/dmwm/CMSMonitoring.git
ARG CGO_ENABLED=0
WORKDIR $WDIR/CMSMonitoring/src/go/intelligence
RUN go build -ldflags="-s -w -extldflags -static"

FROM alpine
RUN mkdir /data
COPY --from=go-builder /data/CMSMonitoring/src/go/intelligence/intelligence /data
ENV PATH $PATH:/data
