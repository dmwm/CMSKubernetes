FROM cmssw/exporters:latest as exporters
FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# tag to use
ENV TAG=v00.00.13

ENV WDIR=/data
ENV USER=cmskv
ADD run.sh $WDIR/run.sh
ADD config.json $WDIR/config.json
WORKDIR $WDIR
RUN mkdir gopath
ENV GOPATH=$WDIR/gopath
ARG CGO_ENABLED=0
RUN git clone https://github.com/vkuznet/cmskv.git
WORKDIR $WDIR/cmskv
RUN git checkout tags/$TAG -b build && make

# for musl C-libary and smallest base image we will use alpine
FROM alpine:3.16
RUN mkdir -p /data/
ENV PATH $PATH:/data
COPY --from=go-builder /data/cmskv/cmskv /data/
COPY --from=go-builder /data/run.sh /data/
COPY --from=go-builder /data/config.json /data/
COPY --from=exporters /data/process_exporter /data/
COPY --from=exporters /data/process_monitor.sh /data/
RUN sed -i -e "s,bash,sh,g" -e "s,print \$2,print \$1,g" /data/process_monitor.sh
