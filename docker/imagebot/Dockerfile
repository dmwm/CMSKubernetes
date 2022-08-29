# Start from the latest golang base image
FROM golang:latest as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV WDIR=/data
WORKDIR $WDIR

# Install latest kubectl for using with crons
RUN curl -ksLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x kubectl

# RUN go get github.com/vkuznet/imagebot
ARG CGO_ENABLED=0
RUN git clone https://github.com/vkuznet/imagebot.git && cd imagebot && make

# final image
FROM alpine:3.16
RUN mkdir -p /data
COPY --from=builder /data/imagebot/imagebot /data/
COPY --from=builder /data/kubectl /usr/bin/
