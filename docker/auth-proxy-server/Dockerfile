FROM golang:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
ENV USER=http
EXPOSE 8181
ADD proxy_auth_server.go $WDIR/proxy_auth_server.go
WORKDIR $WDIR
RUN go mod init github.com/vkuznet/auth-proxy-server
RUN go build proxy_auth_server.go
