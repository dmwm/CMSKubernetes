FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common/log
RUN go get github.com/sirupsen/logrus
RUN go get github.com/vkuznet/x509proxy
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/cmsweb-exporters/master/http_exporter.go
RUN go build http_exporter.go
