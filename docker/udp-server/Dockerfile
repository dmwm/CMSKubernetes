FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
EXPOSE 9331
WORKDIR $WDIR
RUN go mod init github.com/dmwm/udp-collector
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/udp-collector/master/udp_server.go
RUN curl -ksLO https://raw.githubusercontent.com/dmwm/udp-collector/master/udp_server_monitor.go
RUN go build udp_server.go
RUN go build udp_server_monitor.go
