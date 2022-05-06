FROM cern/cc7-base:20220401-1 as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data

RUN yum install -y git-core make golang gcc \
            && yum clean all && rm -rf /var/cache/yum

# get go dependencies
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth && \
    go get github.com/vkuznet/x509proxy && \
    go get -u -d github.com/vkuznet/cmsweb-exporters

# build exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
RUN go build das2go_exporter.go && cp das2go_exporter $WDIR \
    && go build reqmgr_exporter.go && cp reqmgr_exporter $WDIR \
    && go build process_exporter.go && cp process_exporter $WDIR \
    && go build wmcore_exporter.go && cp wmcore_exporter $WDIR \
    && go build cpy_exporter.go && cp cpy_exporter $WDIR \
    && go build cmsweb-ping.go && cp cmsweb-ping $WDIR \
    && cp process_monitor.sh $WDIR

# get filebeat
RUN curl -ksLO https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.10.0-linux-x86_64.tar.gz && \
    tar xfz filebeat-7.10.0-linux-x86_64.tar.gz && \
    cp filebeat-7.10.0-linux-x86_64/filebeat /data

# download node exporter
WORKDIR ${WDIR}
RUN curl -ksLO https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz && tar xfz node_exporter-0.15.2.linux-amd64.tar.gz && cp node_exporter*/node_exporter $WDIR && rm -r node_exporter-0.15.2.linux-amd64/ && rm -r node_exporter-0.15.2.linux-amd64.tar.gz

# build mongo exporter
RUN curl -ksLO https://github.com/dcu/mongodb_exporter/releases/download/v1.0.0/mongodb_exporter-linux-amd64
RUN mv mongodb_exporter-linux-amd64 mongodb_exporter && chmod +x mongodb_exporter

# clean-up
RUN rm -rf /data/gopath

# copy stuff over to base image
FROM cern/cc7-base:20210201-1.x86_64
RUN mkdir -p /data
COPY --from=builder /data /data
