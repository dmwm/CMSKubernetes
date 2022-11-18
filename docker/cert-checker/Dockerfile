FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# build procedure
ENV WDIR=/data
WORKDIR $WDIR
RUN git clone https://github.com/vkuznet/cert-checker.git
ARG CGO_ENABLED=0
WORKDIR $WDIR/cert-checker
RUN go build -ldflags="-s -w -extldflags -static"

# https://blog.baeke.info/2021/03/28/distroless-or-scratch-for-go-apps/
FROM gcr.io/distroless/static AS final
# if we need shell we may use alpine
#FROM alpine:3.16
# RUN mkdir -p /data
COPY --from=go-builder /data/cert-checker/cert-checker /data/
