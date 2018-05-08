FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=dbs
ADD run.sh $WDIR/run.sh
ADD config.json $WDIR/config.json
ADD oci8.pc $WDIR/oci8.pc
ENV PKG_CONFIG_PATH=$WDIR
ADD cernonly2.repo /etc/yum.repos.d/cernonlyw.repo

RUN yum update -y && yum clean all
RUN yum install -y git-core make gcc \
            oracle-instantclient-devel oracle-instantclient-basic
RUN yum clean all

# We need to run under a user different from root, since our software will not install using the root account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# get go dependencies
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/mattn/go-oci8
RUN go get github.com/sirupsen/logrus
RUN go get github.com/vkuznet/dbs2go
RUN go get github.com/shirou/gopsutil

# build dbs2go
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go
RUN sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go
RUN sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go
RUN sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go
RUN make
RUN cat $WDIR/config.json | sed -e "s,GOPATH,$GOPATH,g" > dbsconfig.json
ENV PATH="${GOPATH}/src/github.com/vkuznet/dbs2go:${GOPATH}/src/github.com/vkuznet/dbs2go/bin:${PATH}"
ENV X509_USER_PROXY=/etc/secrets/proxy

# run the service
WORKDIR ${WDIR}
CMD ["run.sh"]
