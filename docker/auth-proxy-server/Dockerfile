FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
WORKDIR $WDIR

# tag to use
ENV TAG=0.1.21

ARG CGO_ENABLED=0
RUN mkdir $WDIR/gopath
ENV GOPATH $WDIR/gopath
RUN go get github.com/go-stomp/stomp && go get github.com/lestrrat-go/file-rotatelogs && go get github.com/vkuznet/lb-stomp
RUN git clone https://github.com/vkuznet/auth-proxy-server.git
WORKDIR $WDIR/auth-proxy-server
RUN git checkout tags/$TAG -b build && make

FROM cmssw/cmsweb-base:latest as cmsweb-base

FROM alpine
RUN mkdir -p /data/static
COPY --from=go-builder /data/auth-proxy-server/auth-proxy-server /data/
COPY --from=go-builder /data/auth-proxy-server/static/cmsmon/index.html /data/static/
COPY --from=cmsweb-base /etc/grid-security /etc/grid-security
