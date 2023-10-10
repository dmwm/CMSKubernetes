FROM golang:latest as go-builder
MAINTAINER Nikodemas Tuckus ntuckus@gmail.com

# tag to use for grafana-backup (gb) script
ENV CMSMON_TAG=gb-0.0.0

ENV WDIR=/data
WORKDIR $WDIR

RUN git clone https://github.com/dmwm/CMSMonitoring.git
WORKDIR $WDIR/CMSMonitoring
RUN git checkout tags/$CMSMON_TAG -b build

ARG CGO_ENABLED=0
WORKDIR $WDIR/CMSMonitoring/src/go/grafana-backup
RUN go build -ldflags="-s -w -extldflags -static" dashboard-exporter.go

FROM alpine:3.17
WORKDIR /data
COPY --from=go-builder /data/CMSMonitoring/src/go/grafana-backup/dashboard-exporter /data/CMSMonitoring/src/go/grafana-backup/run.sh /data/
ENV PATH $PATH:/data
