FROM debian:stable-slim
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
WORKDIR /data
RUN apt-get update && apt-get install -y openssl curl
RUN curl -ksLO https://github.com/prometheus/alertmanager/releases/download/v0.23.0/alertmanager-0.23.0.linux-amd64.tar.gz && \
    tar xfz alertmanager-0.23.0.linux-amd64.tar.gz && \
    mv alertmanager-0.23.0.linux-amd64/amtool . && \
    rm -rf alertmanager-0.23.0.linux-amd64*
# add scripts to run and configuration
ADD run.sh /data/run.sh
