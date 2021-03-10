FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.10.2-amd64.deb
RUN apt-get update && apt-get install -y sudo
RUN sudo dpkg -i filebeat-7.10.2-amd64.deb
FROM debian
COPY --from=go-builder /usr/share/filebeat /usr/share/filebeat/
