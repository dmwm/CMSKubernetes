FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV GOPATH=/data/gopath
RUN mkdir -p $GOPATH
RUN mkdir /build

# get go dependencies
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/buger/jsonparser
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common/log
RUN go get -d github.com/vkuznet/cmsweb-exporters

# download node exporter
RUN curl -k -L -O https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz
RUN tar xfz node_exporter-0.15.2.linux-amd64.tar.gz
RUN cp node_exporter*/node_exporter /build

# build cmsweb exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
ARG CGO_ENABLED=0
RUN go build -o /build/das2go_exporter -ldflags="-s -w -extldflags -static" das2go_exporter.go
RUN go build -o /build/reqmgr_exporter -ldflags="-s -w -extldflags -static" reqmgr_exporter.go
RUN go build -o /build/wmcore_exporter -ldflags="-s -w -extldflags -static" wmcore_exporter.go
RUN go build -o /build/http_exporter -ldflags="-s -w -extldflags -static" http_exporter.go
RUN go build -o /build/process_exporter -ldflags="-s -w -extldflags -static" process_exporter.go
RUN cp process_monitor.sh /build

# build mongo exporter
WORKDIR /tmp
RUN go get github.com/Masterminds/glide
ENV PATH="${GOPATH}/src/github.com/Masterminds/glide:${GOPATH}/bin:${PATH}"
RUN git clone https://github.com/dcu/mongodb_exporter.git $GOPATH/src/github.com/dcu/mongodb_exporter
# TMP: https://github.com/dcu/mongodb_exporter/issues/127
WORKDIR $GOPATH/src/github.com/dcu/mongodb_exporter
RUN cd $GOPATH/src/github.com/dcu/mongodb_exporter
RUN curl -ksLO https://raw.githubusercontent.com/vkuznet/mongodb_exporter/master/collector/metrics.go
RUN mv -f metrics.go collector/metrics.go
RUN cat $GOPATH/src/github.com/dcu/mongodb_exporter/collector/metrics.go
RUN CGO_ENABLED=0 make build
RUN cp mongodb_exporter /build

FROM alpine
RUN mkdir -p /data
COPY --from=go-builder /build/* /data/
ADD run.sh /data/run.sh
ADD probe.sh /data/probe.sh
RUN ln -s /bin/sh /bin/bash
