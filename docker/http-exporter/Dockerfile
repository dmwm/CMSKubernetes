FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR
# go-1.18+ requires go.mod to run go get
RUN go mod init github.com/vkuznet/http-exporter
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common
RUN go get github.com/vkuznet/x509proxy
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/cmsweb-exporters/master/http_exporter.go
RUN mkdir /build
ARG CGO_ENABLED=0
RUN go mod tidy && go build -o /build/http_exporter -ldflags="-s -w -extldflags -static" http_exporter.go

FROM alpine:3.16
RUN mkdir /data
COPY --from=go-builder /build/http_exporter /data/
