FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=das
EXPOSE 8212
ADD mongodb.conf $WDIR/mongodb.conf
ADD das_start.sh $WDIR/das_start.sh

RUN yum update -y && yum clean all
RUN yum install -y git-core krb5-devel readline-devel openssl
RUN yum clean all

# We need to run under a user different from root, since our software will not install using the root account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download mongodb
RUN curl -k -L -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-3.6.2.tgz
RUN tar xfz mongodb-linux-x86_64-rhel70-3.6.2.tgz
ENV MROOT=$WDIR/mongodb-linux-x86_64-rhel70-3.6.2
RUN mkdir -p $WDIR/mongodb/{logs,db}
RUN rm mongodb-linux-x86_64-rhel70-3.6.2.tgz

# get latest DASMaps
RUN git clone https://github.com/dmwm/DASMaps.git

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.9.4.linux-amd64.tar.gz
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.9.4.linux-amd64.tar.gz
RUN tar xfz go1.9.4.linux-amd64.tar.gz
RUN rm go1.9.4.linux-amd64.tar.gz
RUN mkdir $WDIR/gopath
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/mattn/go-oci8
RUN go get github.com/sirupsen/logrus
RUN go get github.com/vkuznet/dbs2go

# build dbs2go
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go
RUN sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go
RUN sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go
RUN sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go
RUN make
ENV PATH="${GOPATH}/src/github.com/vkuznet/dbs2go:${GOPATH}/src/github.com/vkuznet/dbs2go/bin:${PATH}"

USER root
RUN yum remove gcc make perl tcl pinetry -y
USER ${USER}

# run the service
WORKDIR ${WDIR}
CMD ["dbs_start.sh"]
