FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=das
ADD mongodb.conf $WDIR/mongodb.conf
ADD run.sh $WDIR/run.sh
ADD config.json $WDIR/config.json

RUN yum update -y && yum clean all
RUN yum install -y git-core krb5-devel readline-devel openssl
RUN yum clean all

# Create new user account
# RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# USER ${USER}
# if I want to run service under user account I need to run it on non-priveleged
# port. But if kubernetes can't redirect traffic to non-privileged port
# I'll need to add iptables routing of https traffict to local port
# https://wiki.jenkins.io/display/JENKINS/Running+Jenkins+on+Port+80+or+443+using+iptables
# https://unix.stackexchange.com/questions/68714/how-can-i-redirect-ports-80-and-443-to-8080-and-8443-with-iptables
# https://serverfault.com/questions/540241/iptables-how-to-redirect-all-8443-incoming-and-outgoing-to-443

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
RUN curl -k -L -O https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz
RUN tar xfz go1.10.1.linux-amd64.tar.gz
RUN mkdir $WDIR/gopath
RUN rm go1.10.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${MROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get gopkg.in/mgo.v2
RUN go get github.com/sirupsen/logrus
RUN go get github.com/dmwm/das2go

# build das2go
WORKDIR $GOPATH/src/github.com/dmwm/das2go
RUN make
RUN cat $WDIR/config.json | sed -e "s,GOPATH,$GOPATH,g" > dasconfig.json
ENV PATH="${GOPATH}/src/github.com/dmwm/das2go:${GOPATH}/src/github.com/dmwm/das2go/bin:${PATH}"
ENV X509_USER_PROXY=/etc/secrets/proxy

# run the service
WORKDIR ${WDIR}
CMD ["run.sh"]
