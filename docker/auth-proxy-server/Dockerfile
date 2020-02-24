FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
EXPOSE 8181
WORKDIR $WDIR
RUN go mod init github.com/vkuznet/auth-proxy-server
ADD proxy_auth_server.go $WDIR/proxy_auth_server.go
RUN go build proxy_auth_server.go
