FROM golang:1.25-trixie as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# update apt
RUN apt-get update && apt-get -y install unzip libaio1t64 wget

# ORACLE: replace version and put it appropriately in oci8.pc
RUN \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-basic-linux.x64-21.5.0.0.0dbru.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-sqlplus-linux.x64-21.5.0.0.0dbru.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-sdk-linux.x64-21.5.0.0.0dbru.zip && \
unzip instantclient-basic-linux.x64-21.5.0.0.0dbru.zip && \
unzip instantclient-sqlplus-linux.x64-21.5.0.0.0dbru.zip && \
unzip instantclient-sdk-linux.x64-21.5.0.0.0dbru.zip && \
mkdir -p /usr/lib/oracle && \
mv instantclient_21_5 /usr/lib/oracle

# start the setup
ADD oci8.pc /usr/lib/oracle/instantclient_21.5/oci8.pc

# for gibc library we will use debian:stable-slim
FROM debian:stable-slim
RUN apt-get update && apt-get -y install libaio1t64 procps
COPY --from=builder /usr/lib/oracle/instantclient_21_5 /usr/lib/oracle/
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
