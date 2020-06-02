FROM golang:latest as go-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
RUN mkdir -p $WDIR/bin
WORKDIR ${WDIR}

# download mongodb
#RUN curl -k -L -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.6.2.tgz
#RUN tar xfz mongodb-linux-x86_64-rhel70-3.6.2.tgz
#ENV MROOT=$WDIR/mongodb-linux-x86_64-rhel70-3.6.2
#RUN rm mongodb-linux-x86_64-rhel70-3.6.2.tgz
RUN curl -ksLO https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-debian92-3.6.18.tgz
RUN tar xfz mongodb-linux-x86_64-debian92-3.6.18.tgz
ENV MROOT=$WDIR/mongodb-linux-x86_64-debian92-3.6.18
RUN rm mongodb-linux-x86_64-debian92-3.6.18.tgz

# get latest DASMaps
RUN git clone https://github.com/dmwm/DASMaps.git

# get go dependencies
ENV GOPATH=$WDIR/gopath
ARG CGO_ENABLED=0
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${MROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get gopkg.in/mgo.v2
RUN go get github.com/sirupsen/logrus
RUN go get github.com/dmwm/das2go
RUN go get github.com/shirou/gopsutil
RUN go get github.com/uber/go-torch
RUN go get github.com/divan/expvarmon
RUN go get gopkg.in/yaml.v2

# build das2go tools
WORKDIR $GOPATH/src/github.com/dmwm
RUN git clone https://github.com/dmwm/DASTools.git
WORKDIR $GOPATH/src/github.com/dmwm/DASTools
RUN make

# build das2go
WORKDIR $GOPATH/src/github.com/dmwm/das2go
RUN make
RUN go build monitor/das2go_monitor.go
RUN cat $WDIR/config.json | sed -e "s,GOPATH,$GOPATH,g" > dasconfig.json
RUN git clone https://github.com/brendangregg/FlameGraph.git
ENV PATH="${GOPATH}/src/github.com/dmwm/das2go:${PATH}"
ENV PATH="${GOPATH}/src/github.com/dmwm/das2go/FlameGraph:${PATH}"
ENV PATH="${GOPATH}/src/github.com/dmwm/DASTools/bin:${PATH}"

# for musl C-libary and smallest base image we will use alpine
#FROM alpine
# for gibc library we will use debian:stretch
FROM debian:stretch
RUN mkdir -p /data/das2go
ENV PATH $PATH:/data
COPY --from=go-builder /data/gopath/bin /data/
COPY --from=go-builder /data/gopath/src/github.com/dmwm/DASTools/bin /data/
COPY --from=go-builder /data/gopath/src/github.com/dmwm/das2go/bin /data/
COPY --from=go-builder /data/gopath/src/github.com/dmwm/das2go/templates /data/templates
COPY --from=go-builder /data/gopath/src/github.com/dmwm/das2go/das2go_monitor /data/
COPY --from=go-builder /data/mongodb-linux-x86_64-debian92-3.6.18/bin /data/
RUN mkdir -p /data/mongodb/db
RUN mkdir -p /data/mongodb/logs
RUN apt-get update
RUN apt-get -y install openssl
ADD config.json /data/config.json
ADD run.sh /data/run.sh
ADD monitor.sh /data/monitor.sh
ADD mongodb.conf /data/mongodb.conf
WORKDIR /data
CMD ["run.sh"]
