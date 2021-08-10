FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# DAS tag to use
ENV TAG=00.00.07

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath && mkdir /build
ENV GOPATH=/data/gopath
WORKDIR /data/dbsproxy
RUN git clone https://github.com/vkuznet/dbsproxy
ARG CGO_ENABLED=0
RUN cd dbsproxy && git checkout tags/$TAG -b build && make && cp dbsproxy /build

# FROM alpine
# RUN mkdir -p /data
# https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/
FROM gcr.io/distroless/static AS final
COPY --from=go-builder /build/dbsproxy /data/
