FROM cmssw/exporters:latest as exporters
FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# tag to use
ENV TAG=00.00.01

ENV WDIR=/data
ENV USER=wmstats
WORKDIR $WDIR
RUN mkdir gopath
ENV GOPATH=$WDIR/gopath
ARG CGO_ENABLED=0
RUN git clone https://github.com/vkuznet/wmstats.git
WORKDIR $WDIR/wmstats
RUN git checkout tags/$TAG -b build && make

# for musl C-libary and smallest base image we will use alpine
FROM alpine:3.15
# for distroless distribution
# FROM gcr.io/distroless/static AS final
RUN mkdir -p /data/
ENV PATH $PATH:/data
COPY --from=go-builder /data/wmstats/wmstats /data/
COPY --from=go-builder /data/wmstats/static /data/static
