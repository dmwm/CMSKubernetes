FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath && mkdir /build
ENV GOPATH=/data/gopath
ARG CGO_ENABLED=0
RUN curl -ksLO https://raw.githubusercontent.com/yuyiguo/CMSRucio/FWJRGo/docker/CMSRucioClient/traces/src/go/stompserver.go
RUN go mod init github.com/dmwm/rucio-trafer && go mod tidy && \
    go build -o /build/rucio-tracer -ldflags="-s -w -extldflags -static" /data/stompserver.go

FROM alpine
RUN mkdir -p /data
COPY --from=go-builder /build/rucio-tracer /data/
