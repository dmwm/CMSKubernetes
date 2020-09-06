FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
WORKDIR $WDIR
ARG CGO_ENABLED=0
RUN mkdir $WDIR/gopath
ENV GOPATH $WDIR/gopath
RUN go get -u -ldflags="-s -w -extldflags -static" github.com/vkuznet/auth-proxy-server
RUN curl -ksLO "https://raw.githubusercontent.com/vkuznet/auth-proxy-server/master/static/cmsmon/index.html"

FROM cmssw/cmsweb-base:latest as cmsweb-base

FROM alpine
RUN mkdir -p /data/static
COPY --from=go-builder /data/gopath/bin/auth-proxy-server /data/
COPY --from=go-builder /data/index.html /data/static/
COPY --from=cmsweb-base /etc/grid-security /etc/grid-security
