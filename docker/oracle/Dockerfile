FROM golang:1.25-trixie as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# update apt
RUN apt-get update && apt-get -y install unzip libaio1t64 wget

# ORACLE: replace version and put it appropriately in oci8.pc
RUN \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/2390000/instantclient-basic-linux.x64-23.9.0.25.07.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/2390000/instantclient-sqlplus-linux.x64-23.9.0.25.07.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/2390000/instantclient-sdk-linux.x64-23.9.0.25.07.zip && \
unzip -oq instantclient-basic-linux.x64-23.9.0.25.07.zip && \
unzip -oq instantclient-sqlplus-linux.x64-23.9.0.25.07.zip && \
unzip -oq instantclient-sdk-linux.x64-23.9.0.25.07.zip && \
mkdir -p /usr/lib/oracle && \
mv instantclient_23_9 /usr/lib/oracle

# start the setup
ADD oci8.pc /usr/lib/oracle/instantclient_23_9/oci8.pc

# for gibc library we will use debian:stable-slim
FROM debian:stable-slim
RUN apt-get update && apt-get -y install libaio1t64 procps
COPY --from=builder /usr/lib/oracle/instantclient_23_9 /usr/lib/oracle/
RUN ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64.0.2 /usr/lib/x86_64-linux-gnu/libaio.so.1
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
