FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir /data/gopath
RUN mkdir /build
ENV GOPATH=/data/gopath
RUN go get gopkg.in/yaml.v2
RUN git clone https://github.com/dmwm/DASTools
RUN git clone https://github.com/dmwm/das2go
ARG CGO_ENABLED=0
RUN go build -o /build/das2go_monitor -ldflags="-s -w -extldflags -static" /data/das2go/monitor/das2go_monitor.go
WORKDIR /data/das2go
RUN go build -o /build/das2go -ldflags="-s -w -extldflags -static"
RUN cp -r js css images templates /build
WORKDIR /data
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/cmsweb-exporters/master/das2go_exporter.go
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/prometheus/common/log
RUN go get github.com/prometheus/client_golang/prometheus
RUN go build -o /build/das2go_exporter -ldflags="-s -w -extldflags -static" /data/das2go_exporter.go

FROM alpine
RUN mkdir -p /data
COPY --from=go-builder /build/das* /data/
COPY --from=go-builder /build/js /data/js
COPY --from=go-builder /build/css /data/css
COPY --from=go-builder /build/images /data/images
COPY --from=go-builder /build/templates /data/templates
ADD run.sh /data/run.sh
