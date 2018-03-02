FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=dbs
EXPOSE 8989
ADD dbs_start.sh $WDIR/dbs_start.sh
ADD oci8.pc $WDIR/oci8.pc
ENV PKG_CONFIG_PATH=$WDIR
ADD cernonly2.repo /etc/yum.repos.d/cernonlyw.repo

RUN yum update -y && yum clean all
RUN yum install -y git-core krb5-devel readline-devel\
            bzip2 git-core krb5-devel readline-devel openssl \
            gcc gcc-c++ libgcc \
            oracle-instantclient-devel oracle-instantclient-basic \
            glibc-devel.x86_64 e2fsprogs e2fsprogs-libs compat-libstdc++-33 make vim-enhanced
RUN yum clean all

#RUN yum search oracle-instantclient

# We need to run under a user different from root, since our software will not install using the root account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.9.4.linux-amd64.tar.gz
RUN tar xfz go1.9.4.linux-amd64.tar.gz
RUN mkdir $WDIR/gopath
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/mattn/go-oci8
#RUN go get github.com/go-sql-driver/mysql
#RUN go get github.com/mattn/go-sqlite3
#RUN go get gopkg.in/rana/ora.v4
RUN go get github.com/sirupsen/logrus
RUN go get github.com/vkuznet/dbs2go

# build dbs2go
WORKDIR $GOPATH/src/github.com/vkuznet/dbs2go
RUN sed -i -e "s,_ \"gopkg.in/rana/ora.v4\",,g" web/server.go
RUN sed -i -e "s,_ \"github.com/mattn/go-sqlite3\",,g" web/server.go
RUN sed -i -e "s,_ \"github.com/go-sql-driver/mysql\",,g" web/server.go
RUN make
ENV PATH="${GOPATH}/src/github.com/vkuznet/dbs2go:${GOPATH}/src/github.com/vkuznet/dbs2go/bin:${PATH}"

# run the service
WORKDIR ${WDIR}
CMD ["dbs_start.sh"]
