FROM cmssw/exporters:latest as exporters
FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# DAS tag to use
ENV TAG=v00.08.55

ENV WDIR=/data
ENV USER=wmarchive
ADD run.sh $WDIR/run.sh
ADD wmarch_go.json $WDIR/wmarch_go.json
WORKDIR $WDIR
RUN mkdir gopath
ENV GOPATH=$WDIR/gopath
ARG CGO_ENABLED=0
RUN go get github.com/go-stomp/stomp && go get github.com/google/uuid
RUN git clone https://github.com/dmwm/WMArchive.git
WORKDIR $WDIR/WMArchive
RUN git checkout tags/$TAG -b build && go build -o $WDIR/wmarchive src/go/wmarchive.go

# for musl C-libary and smallest base image we will use alpine
FROM alpine
RUN mkdir -p /data/
ENV PATH $PATH:/data
COPY --from=go-builder /data/wmarchive /data/
COPY --from=go-builder /data/run.sh /data/
COPY --from=go-builder /data/wmarch_go.json /data/
COPY --from=exporters /data/process_exporter /data/
COPY --from=exporters /data/process_monitor.sh /data/
