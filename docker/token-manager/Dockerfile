FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
WORKDIR /data
#RUN go mod init github.com/vkuznet/auth-proxy-server
RUN curl -ksLO https://raw.githubusercontent.com/vkuznet/auth-proxy-server/master/manager/token.go
RUN CGO_ENABLED=0 go build -o token-manager -ldflags="-s -w -extldflags -static" token.go

FROM alpine:3.16
COPY --from=go-builder /data/token-manager /usr/bin/
