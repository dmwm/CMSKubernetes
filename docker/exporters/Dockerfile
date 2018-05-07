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
RUN mkdir -p $WDIR/bin
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
RUN go get github.com/buger/jsonparser
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common/log
RUN go get -d github.com/vkuznet/cmsweb-exporters

# download and install grafana for prometheus
WORKDIR ${WDIR}
RUN curl -L -O https://grafanarel.s3.amazonaws.com/builds/grafana-2.5.0.linux-x64.tar.gz
RUN tar zxf grafana-2.5.0.linux-x64.tar.gz
RUN mv grafana-2.5.0 grafana
RUN rm grafana-2.5.0.linux-x64.tar.gz

# download node exporter
WORKDIR ${WDIR}
RUN curl -k -L -O https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz
RUN tar xfz node_exporter-0.15.2.linux-amd64.tar.gz
RUN cp node_exporter*/node_exporter $WDIR/bin

# build exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
RUN go build das2go_exporter.go
RUN cp das2go_exporter $WDIR/bin
ENV PATH="${GOPATH}/src/github.com/vkuznet/cmsweb-exporters:${GOPATH}/src/github.com/vkuznet/cmsweb-exporters/bin:${PATH}"
ENV X509_USER_PROXY=/etc/secrets/proxy

# run the service
WORKDIR ${WDIR}
CMD ["run.sh"]
