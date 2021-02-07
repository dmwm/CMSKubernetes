FROM cern/cc7-base:20201101-1.x86_64 as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_dbs
ADD oci8.pc $WDIR/oci8.pc
ENV PKG_CONFIG_PATH=$WDIR
ADD cernonly2.repo /etc/yum.repos.d/cernonlyw.repo
ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
ADD epel.repo /etc/yum.repos.d/epel.repo

RUN yum install -y git-core make gcc golang sudo oracle-instantclient-tnsnames.ora \
            oracle-instantclient-devel oracle-instantclient-basic \
            && yum clean all && rm -rf /var/cache/yum

# Create new user account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# get go dependencies
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth && \
    go get github.com/vkuznet/x509proxy && \
    go get github.com/mattn/go-oci8 && \
    go get github.com/gorilla/csrf && \
    go get github.com/gorilla/mux && \
    go get github.com/lestrrat-go/file-rotatelogs && \
    go get golang.org/x/sys/unix && \
    go get github.com/shirou/gopsutil && \
    go get github.com/mattn/go-sqlite3 && \
    go get golang.org/x/exp/errors && \
    go get -u -d github.com/vkuznet/cmsweb-exporters

# build process_monitor
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
RUN go build process_exporter.go && cp process_exporter $WDIR && cp process_monitor.sh $WDIR

# get filebeat
RUN curl -ksLO https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.10.0-linux-x86_64.tar.gz && \
    tar xfz filebeat-7.10.0-linux-x86_64.tar.gz && \
    cp filebeat-7.10.0-linux-x86_64/filebeat /data

ADD config.json $WDIR/config.json
ENV PATH="${GOPATH}/src/github.com/vkuznet/dbs2go:${GOPATH}/src/github.com/vkuznet/dbs2go/bin:${PATH}"
ENV X509_USER_PROXY=/data/srv/current/auth/proxy/proxy

# build dbs2go with specific tag
ENV TAG=v00.00.77
WORKDIR $GOPATH/src/github.com/vkuznet
RUN git clone https://github.com/vkuznet/dbs2go
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go
RUN git checkout tags/$TAG -b build && \
    sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go && \
    sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go && \
    make
RUN cat $WDIR/config.json | sed -e "s,GOPATH,$GOPATH,g" > dbsconfig.json

FROM cern/cc7-base:20201101-1.x86_64
RUN yum install -y libaio && yum clean all && rm -rf /var/cache/yum
RUN mkdir -p /data
COPY --from=builder /data/gopath/src/github.com/vkuznet/dbs2go/dbs2go /data/
COPY --from=builder /data/gopath /data/gopath
COPY --from=builder /usr/lib/oracle /usr/lib/oracle
COPY --from=builder /etc/tnsnames.ora /etc
COPY --from=builder /data/filebeat /usr/bin/filebeat
COPY --from=builder /data/process_exporter /data
COPY --from=builder /data/process_monitor.sh /data

# run the service
ENV PATH="/data/gopath/bin:/data:${PATH}"
RUN cp /data/gopath/src/github.com/vkuznet/dbs2go/dbsconfig.json /data/config.json
ADD monitor.sh /data/monitor.sh
ADD run.sh /data/run.sh
WORKDIR /data
CMD ["run.sh"]
