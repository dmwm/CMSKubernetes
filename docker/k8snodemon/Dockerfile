FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# DAS tag to use
ENV TAG=00.00.00

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath && mkdir /build
ENV GOPATH=/data/gopath
ARG CGO_ENABLED=0
RUN git clone https://github.com/vkuznet/k8snodemon && cd k8snodemon && \
    git checkout tags/$TAG -b build && make && cp k8snodemon /build

FROM alpine:3.16
RUN mkdir -p /data
COPY --from=go-builder /build/k8snodemon /data/
