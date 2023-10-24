FROM registry.cern.ch/cmsweb/oracle:21_5-stable as oracle
#FROM cmssw/oracle:21_1 as oracle
FROM cmssw/exporters:latest as exporters
FROM cmssw/filebeat:latest as filebeat
FROM golang:latest as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# get oracle for our build
COPY --from=oracle /usr/lib/oracle /usr/lib/oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle

# update apt
#RUN apt-get update && apt-get -y install unzip

# start the setup
ENV WDIR=/data
RUN mkdir -p $WDIR
WORKDIR ${WDIR}
ADD oci8.pc $WDIR/oci8.pc
ENV PKG_CONFIG_PATH=$WDIR

# build dbs2go with specific tag
ENV TAG=v00.06.09
WORKDIR $GOPATH/src/github.com/vkuznet
RUN git clone https://github.com/vkuznet/dbs2go && \
    git clone https://github.com/vkuznet/cmsweb-exporters
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go

# example how to checkout specific branch
# RUN git checkout --track origin/api-struct && \
RUN git checkout tags/$TAG -b build && \
    sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go && \
    make && cp -r dbs2go static $WDIR

# Install latest kubectl
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN mv kubectl /usr/bin
RUN chmod +x /usr/bin/kubectl

# for gibc library we will use debian:stretch
FROM debian:stable-slim
RUN apt-get update && apt-get -y install libaio1 procps && mkdir -p /data
ENV WDIR=/data
ENV USER=_dbs2go
# add new user
RUN useradd -d ${WDIR} ${USER} # && install -o ${USER} -d ${WDIR}
RUN mkdir -p /data
COPY --from=builder /data /data
COPY --from=exporters /data/process_exporter /data
COPY --from=exporters /data/process_monitor.sh /data
COPY --from=filebeat /usr/share/filebeat /usr/share/filebeat
COPY --from=filebeat /usr/bin/filebeat /usr/bin/filebeat
COPY --from=oracle /usr/lib/oracle /usr/lib/oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle

COPY --from=builder /usr/bin/kubectl /usr/bin/kubectl

# run the service
ENV PATH="/data/gopath/bin:/data:${PATH}"
ADD monitor.sh /data/monitor.sh
ADD run.sh /data/run.sh
ADD config.json /data/config.json
RUN chown -R $USER.$USER /data && chown -R $USER.$USER /usr/lib/oracle && chown -R $USER.$USER /usr/bin/filebeat
RUN chmod +x /data/*.sh
USER $USER
WORKDIR /data
# CMD ["run.sh"]
