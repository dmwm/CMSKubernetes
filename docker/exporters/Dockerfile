FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=exporters
ADD run.sh $WDIR/run.sh

RUN yum update -y && yum clean all
RUN yum install -y git-core krb5-devel readline-devel openssl
RUN yum clean all

# Create new user account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz
RUN tar xfz go1.10.1.linux-amd64.tar.gz
RUN mkdir $WDIR/gopath
RUN rm go1.10.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/vkuznet/cmsweb-exporters
RUN go get github.com/buger/jsonparser
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common/log

# build exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
RUN go build das2go_exporter.go
ENV PATH="${GOPATH}/src/github.com/vkuznet/cmsweb-exporters:${GOPATH}/src/github.com/vkuznet/cmsweb-exporters/bin:${PATH}"
ENV X509_USER_PROXY=/etc/secrets/exporters-proxy

# run the service
WORKDIR ${WDIR}
CMD ["run.sh"]
