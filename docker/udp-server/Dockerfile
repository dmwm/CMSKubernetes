FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
EXPOSE 9331
ADD udp_server.go $WDIR/udp_server.go
WORKDIR $WDIR
RUN go mod init github.com/vkuznet/udp-server
RUN go build udp_server.go
