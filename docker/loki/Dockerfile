FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN apt-get update && apt-get install -y unzip
RUN curl -ksLO https://github.com/grafana/loki/releases/download/v2.6.1/loki-linux-amd64.zip && \
    unzip loki-linux-amd64.zip && mv loki-linux-amd64 loki

FROM alpine:3.16
RUN mkdir -p /data
COPY --from=go-builder /go/loki /data/
