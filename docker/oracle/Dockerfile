FROM golang:latest as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# update apt
RUN apt-get update && apt-get -y install unzip libaio1 wget

# ORACLE: replace version and put it appropriately in oci8.pc
RUN \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
unzip instantclient-basic-linux.x64-21.1.0.0.0.zip && \
unzip instantclient-sqlplus-linux.x64-21.1.0.0.0.zip && \
unzip instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
mkdir -p /usr/lib/oracle && \
mv instantclient_21_1 /usr/lib/oracle

# start the setup
ADD oci8.pc /usr/lib/oracle/instantclient_21_1/oci8.pc

# for gibc library we will use debian:buster-slim
FROM debian:buster-slim
RUN apt-get update && apt-get -y install libaio1 procps
COPY --from=builder /usr/lib/oracle/instantclient_21_1 /usr/lib/oracle/
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
