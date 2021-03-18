FROM golang:latest as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# update apt
RUN apt-get update && apt-get -y install unzip libaio1 wget && \
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list && \
    apt-get install apt-transport-https && \
    apt update && \
    apt -y install filebeat

# download ORACLE
RUN \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-basic-linux.x64-19.10.0.0.0dbru.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-sqlplus-linux.x64-19.10.0.0.0dbru.zip && \
curl -ksLO https://download.oracle.com/otn_software/linux/instantclient/191000/instantclient-sdk-linux.x64-19.10.0.0.0dbru.zip && \
unzip instantclient-basic-linux.x64-19.10.0.0.0dbru.zip && \
unzip instantclient-sqlplus-linux.x64-19.10.0.0.0dbru.zip && \
unzip instantclient-sdk-linux.x64-19.10.0.0.0dbru.zip && \
mkdir -p /usr/lib/oracle && \
mv instantclient_19_10 /usr/lib/oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle/instantclient_19_10
ENV PATH=$PATH:/usr/lib/oracle/instantclient_19_10

# start the setup
ENV WDIR=/data
ADD oci8.pc $WDIR/oci8.pc
ENV PKG_CONFIG_PATH=$WDIR

RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# build dbs2go with specific tag
ENV TAG=v00.01.05
WORKDIR $GOPATH/src/github.com/vkuznet
RUN git clone https://github.com/vkuznet/dbs2go && \
    git clone https://github.com/vkuznet/cmsweb-exporters
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go
RUN git checkout tags/$TAG -b build && \
    sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go && \
    make && cp -r dbs2go static $WDIR

# build exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
RUN go mod init github.com/vkuznet/cmsweb-exporters && go mod tidy && \
    go build process_exporter.go && cp process_exporter $WDIR && \
    cp process_monitor.sh $WDIR

# for gibc library we will use debian:stretch
FROM debian:stretch
RUN apt-get update && apt-get -y install libaio1 procps && mkdir -p /data
COPY --from=builder /data /data
COPY --from=builder /usr/bin/filebeat /usr/bin/filebeat
COPY --from=builder /usr/lib/oracle/instantclient_19_10 /usr/lib/oracle/

# run the service
ENV PATH="/data/gopath/bin:/data:${PATH}"
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ADD monitor.sh /data/monitor.sh
ADD run.sh /data/run.sh
ADD config.json /data/config.json
RUN chmod +x /data/*.sh
WORKDIR /data
# CMD ["run.sh"]
