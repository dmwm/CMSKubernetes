FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN apt-get update && apt-get install -y unzip
RUN curl -ksLO https://github.com/grafana/loki/releases/download/v2.6.1/promtail-linux-amd64.zip && \
    unzip promtail-linux-amd64.zip && mv promtail-linux-amd64 promtail

FROM debian:stable-slim
RUN mkdir -p /data
COPY --from=go-builder /go/promtail /data/
