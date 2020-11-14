FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# DAS tag to use
ENV TAG=04.06.44

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath && mkdir /build
ENV GOPATH=/data/gopath
RUN go get gopkg.in/yaml.v2 && \
    git clone https://github.com/dmwm/DASTools && \
    git clone https://github.com/dmwm/das2go
WORKDIR /data/das2go
ARG CGO_ENABLED=0
RUN git checkout tags/$TAG -b build && make && cp das2go /build
RUN go build -o /build/das2go_monitor -ldflags="-s -w -extldflags -static" /data/das2go/monitor/das2go_monitor.go
RUN cp -r js css images templates examples /build
WORKDIR /data
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/cmsweb-exporters/master/das2go_exporter.go
RUN go get github.com/vkuznet/x509proxy && \
    go get github.com/prometheus/common/log && \
    go get github.com/prometheus/client_golang/prometheus
RUN go build -o /build/das2go_exporter -ldflags="-s -w -extldflags -static" /data/das2go_exporter.go

FROM alpine
RUN mkdir -p /data
COPY --from=go-builder /build/das* /data/
COPY --from=go-builder /build/js /data/js
COPY --from=go-builder /build/css /data/css
COPY --from=go-builder /build/images /data/images
COPY --from=go-builder /build/templates /data/templates
COPY --from=go-builder /build/examples /data/examples
ADD run.sh /data/run.sh
