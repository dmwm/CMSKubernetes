FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
WORKDIR $WDIR

# tag to use
ENV TAG=0.2.81

ARG CGO_ENABLED=0
RUN mkdir $WDIR/gopath
ENV GOPATH $WDIR/gopath
RUN git clone https://github.com/vkuznet/auth-proxy-server.git
WORKDIR $WDIR/auth-proxy-server
RUN git checkout tags/$TAG -b build && make

# https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/
# FROM alpine
FROM gcr.io/distroless/static AS final
#RUN mkdir -p /data/static && mkdir -p /data/srv/logs/frontend
COPY --from=go-builder /data/auth-proxy-server/auth-proxy-server /data/
COPY --from=go-builder /data/auth-proxy-server/static/cmsmon/index.html /data/static/
