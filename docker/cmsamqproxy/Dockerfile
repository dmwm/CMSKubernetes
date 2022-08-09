FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# DAS tag to use
ENV TAG=00.00.14

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath
ENV GOPATH=/data/gopath
ARG CGO_ENABLED=0
RUN git clone https://github.com/vkuznet/CMSAMQProxy
WORKDIR /data/CMSAMQProxy
RUN git checkout tags/$TAG -b build && make

# FROM alpine
# RUN mkdir -p /data
# https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/
FROM gcr.io/distroless/static AS final
COPY --from=go-builder /data/CMSAMQProxy/cmsamqproxy /data/
