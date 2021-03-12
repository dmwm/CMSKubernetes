FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
#RUN apt-get update && apt-get -y install cron
ENV WDIR=/data
WORKDIR $WDIR
ENV PATH $PATH:$WDIR:$WDIR/CMSMonitoring/scripts

# tag to use
ENV TAG=0.5.25

RUN git clone https://github.com/dmwm/CMSMonitoring.git
WORKDIR $WDIR/CMSMonitoring
RUN git checkout tags/$TAG -b build
ARG CGO_ENABLED=0
WORKDIR $WDIR/CMSMonitoring/src/go/MONIT
RUN go build -ldflags="-s -w -extldflags -static" monit.go
RUN go build -ldflags="-s -w -extldflags -static" ssb_alerting.go
RUN go build -ldflags="-s -w -extldflags -static" ggus_parser.go
RUN go build -ldflags="-s -w -extldflags -static" ggus_alerting.go
RUN go build -ldflags="-s -w -extldflags -static" es_exporter.go
RUN go build -ldflags="-s -w -extldflags -static" hdfs_exporter.go

FROM alpine
RUN mkdir /data
COPY --from=go-builder /data/CMSMonitoring/src/go/MONIT/monit /data
COPY --from=go-builder /data/CMSMonitoring/src/go/MONIT/ssb_alerting /data
COPY --from=go-builder /data/CMSMonitoring/src/go/MONIT/ggus_parser /data
COPY --from=go-builder /data/CMSMonitoring/src/go/MONIT/ggus_alerting /data
COPY --from=go-builder /data/CMSMonitoring/src/go/MONIT/es_exporter /data
COPY --from=go-builder /data/CMSMonitoring/src/go/MONIT/hdfs_exporter /data
COPY --from=go-builder /data/CMSMonitoring/scripts /data
ENV PATH $PATH:/data
