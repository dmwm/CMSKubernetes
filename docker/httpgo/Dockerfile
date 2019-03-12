FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=http
EXPOSE 8888
ADD httpgo.go $WDIR/httpgo.go

#RUN yum update -y && yum clean all
#RUN yum install -y git-core krb5-devel readline-devel openssl
#RUN yum clean all

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
RUN rm go1.9.4.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# build httpgo server
RUN go build httpgo.go

# run the service
WORKDIR ${WDIR}
CMD ["httpgo"]
