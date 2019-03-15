FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ADD httpsgo.go $WDIR/httpsgo.go
ADD config.json $WDIR/config.json
ADD run.sh $WDIR/run.sh

#RUN yum update -y && yum clean all
#RUN yum install -y git-core krb5-devel readline-devel openssl
#RUN yum clean all

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
RUN tar xfz go1.12.1.linux-amd64.tar.gz
RUN mkdir $WDIR/gopath
RUN rm go1.12.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# build httpsgo server
RUN go build httpsgo.go

# run the service
WORKDIR ${WDIR}
CMD ["run.sh"]
