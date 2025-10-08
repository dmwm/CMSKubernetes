FROM golang:1.25-trixie as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# update apt
RUN apt-get update && apt-get -y install unzip libaio1t64 wget

# ORACLE: replace version and put it appropriately in oci8.pc
RUN \
apt-get update && apt-get -y install alien && \
curl -ksLO https://linuxsoft.cern.ch/mirror/yum.oracle.com/repo/OracleLinux/OL9/oracle/instantclient23/x86_64/getPackage/oracle-instantclient-tools-23.9.0.25.07-1.el9.x86_64.rpm && \
curl -ksLO https://linuxsoft.cern.ch/mirror/yum.oracle.com/repo/OracleLinux/OL9/oracle/instantclient23/x86_64/getPackage/oracle-instantclient-sqlplus-23.9.0.25.07-1.el9.x86_64.rpm && \
curl -ksLO https://linuxsoft.cern.ch/mirror/yum.oracle.com/repo/OracleLinux/OL9/oracle/instantclient23/x86_64/getPackage/oracle-instantclient-odbc-23.9.0.25.07-1.el9.x86_64.rpm && \
curl -ksLO https://linuxsoft.cern.ch/mirror/yum.oracle.com/repo/OracleLinux/OL9/oracle/instantclient23/x86_64/getPackage/oracle-instantclient-jdbc-23.9.0.25.07-1.el9.x86_64.rpm && \
curl -ksLO https://linuxsoft.cern.ch/mirror/yum.oracle.com/repo/OracleLinux/OL9/oracle/instantclient23/x86_64/getPackage/oracle-instantclient-devel-23.9.0.25.07-1.el9.x86_64.rpm && \
curl -ksLO https://linuxsoft.cern.ch/mirror/yum.oracle.com/repo/OracleLinux/OL9/oracle/instantclient23/x86_64/getPackage/oracle-instantclient-basic-23.9.0.25.07-1.el9.x86_64.rpm && \
alien -i --scripts oracle-instantclient-*.rpm

# start the setup
ADD oci8.pc /usr/lib/oracle/oci8.pc

# for gibc library we will use debian:stable-slim
FROM debian:stable-slim
RUN apt-get update && apt-get -y install libaio1t64 procps
COPY --from=builder /usr/lib/oracle/ /usr/lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64.0.2 /usr/lib/x86_64-linux-gnu/libaio.so.1
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
