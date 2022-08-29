FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN mkdir -p /data/gopath && mkdir /build
# Install latest kubectl
RUN curl -s -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && mv kubectl /usr/bin && chmod +x /usr/bin/kubectl
ADD check-metric.go $WDIR/check-metric.go
ARG CGO_ENABLED=0
RUN go build -o /build/check-metric -ldflags="-s -w -extldflags -static" /data/check-metric.go

FROM alpine:3.16
RUN mkdir -p /data
COPY --from=go-builder /build/check-metric /data/
COPY --from=go-builder /usr/bin/kubectl /data/
