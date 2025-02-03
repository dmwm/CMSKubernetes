FROM golang:latest as go-builder

# tag to use
ARG CMSMON_TAG=sqoop-0.0.0
ENV CMSMON_TAG=$CMSMON_TAG

ENV WDIR=/data
WORKDIR $WDIR

RUN git clone https://github.com/dmwm/CMSMonitoring.git
WORKDIR $WDIR/CMSMonitoring
RUN git checkout tags/$CMSMON_TAG -b build

# cms-monitoring es-sizes
WORKDIR $WDIR
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${PATH}:${GOROOT}/bin:${WDIR}"
WORKDIR $WDIR/CMSMonitoring/src/go/MONIT
RUN go get github.com/go-stomp/stomp
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/client_golang/prometheus/promhttp
RUN CGO_ENABLED=0 go build -ldflags "-s -w -extldflags '-static'" monit.go && \
    CGO_ENABLED=0 go build -ldflags "-s -w -extldflags '-static'" hdfs_exporter.go && \
    cp monit hdfs_exporter $WDIR
WORKDIR $WDIR

# get amtool
RUN curl -ksLO https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz
RUN tar xfz alertmanager-0.24.0.linux-amd64.tar.gz && mv alertmanager-0.24.0.linux-amd64/amtool $WDIR/ && rm -rf alertmanager-0.24.0.linux-amd64*


FROM registry.cern.ch/cmsmonitoring/cmsmon-hadoop-base:spark2-latest
# Do not use spark3, it requires additional settings
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ENV WDIR=/data
WORKDIR $WDIR

COPY --from=go-builder /data/amtool /data
COPY --from=go-builder /data/hdfs_exporter /data
COPY --from=go-builder /data/monit /data
COPY --from=go-builder /data/CMSMonitoring/sqoop /data/sqoop

WORKDIR $WDIR/sqoop
RUN mkdir -p $WDIR/sqoop/log && \
# Create symbolic link of below files in $WDIR/sqoop directory
    ln -s /etc/cmsdb/cmsr_cstring && ln -s /etc/cmsdb/lcgr_cstring && \
    crontab cronjobs.txt

WORKDIR $WDIR
