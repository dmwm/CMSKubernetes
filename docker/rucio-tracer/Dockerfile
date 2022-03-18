FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/{server,messanger,gopath} && mkdir /build
ENV GOPATH=/data/gopath
ARG CGO_ENABLED=0
WORKDIR $WDIR/server
RUN curl -ksLO https://raw.githubusercontent.com/vkuznet/RucioTraces/main/server/main.go
RUN go mod init github.com/vkuznet/RucioTraces/server && go mod tidy && \
    go build -o /build/rucio-tracer -ldflags="-s -w -extldflags -static" /data/server/main.go
WORKDIR $WDIR/messanger
RUN curl -ksLO https://raw.githubusercontent.com/vkuznet/RucioTraces/main/messanger/main.go
RUN go mod init github.com/vkuznet/RucioTraces/messanger && go mod tidy && \
    go build -o /build/rucio-messanger -ldflags="-s -w -extldflags -static" /data/messanger/main.go

FROM alpine:3.15
RUN mkdir -p /data
COPY --from=go-builder /build/rucio-tracer /data/
COPY --from=go-builder /build/rucio-messanger /data/
