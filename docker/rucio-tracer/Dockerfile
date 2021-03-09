FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath && mkdir /build
ENV GOPATH=/data/gopath
ARG CGO_ENABLED=0
RUN curl -ksLO https://raw.githubusercontent.com/vkuznet/RucioTraces/main/server/main.go
RUN go mod init github.com/vkuznet/RucioTraces/server && go mod tidy && \
    go build -o /build/rucio-tracer -ldflags="-s -w -extldflags -static" /data/main.go

FROM alpine
RUN mkdir -p /data
COPY --from=go-builder /build/rucio-tracer /data/
