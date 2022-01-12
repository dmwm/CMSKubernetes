FROM golang:1
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
EXPOSE 9331
WORKDIR $WDIR
# DAS tag to use
ENV TAG=v00.00.04

RUN git clone https://github.com/dmwm/udp-collector
WORKDIR $WDIR/udp-collector
ARG CGO_ENABLED=0
RUN git checkout tags/$TAG -b build && make
