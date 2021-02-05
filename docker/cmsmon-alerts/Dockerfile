FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
#RUN apt-get update && apt-get -y install cron
ENV WDIR=/data
WORKDIR $WDIR
ENV PATH $PATH:$WDIR:$WDIR/CMSMonitoring/scripts
RUN mkdir gopath
ENV GOPATH $WDIR/gopath
RUN go get github.com/go-stomp/stomp
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/client_golang/prometheus/promhttp

# tag to use
ENV TAG=0.5.17

RUN git clone https://github.com/dmwm/CMSMonitoring.git
WORKDIR $WDIR/CMSMonitoring
RUN git checkout tags/$TAG -b build
ARG CGO_ENABLED=0
RUN go build -ldflags="-s -w -extldflags -static" src/go/MONIT/monit.go
RUN go build -ldflags="-s -w -extldflags -static" src/go/MONIT/ssb_alerting.go
RUN go build -ldflags="-s -w -extldflags -static" src/go/MONIT/ggus_parser.go
RUN go build -ldflags="-s -w -extldflags -static" src/go/MONIT/ggus_alerting.go
RUN go build -ldflags="-s -w -extldflags -static" src/go/MONIT/es_exporter.go

FROM alpine
RUN mkdir /data
COPY --from=go-builder /data/CMSMonitoring/monit /data
COPY --from=go-builder /data/CMSMonitoring/ssb_alerting /data
COPY --from=go-builder /data/CMSMonitoring/ggus_parser /data
COPY --from=go-builder /data/CMSMonitoring/ggus_alerting /data
COPY --from=go-builder /data/CMSMonitoring/es_exporter /data
COPY --from=go-builder /data/CMSMonitoring/scripts /data
ENV PATH $PATH:/data
