FROM registry.cern.ch/cmsweb/cmsweb-base:20221130-stable as web-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_cmsweb

# create bashs link to bash
#RUN ln -s /bin/bash /usr/bin/bashs
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR} && echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# add fake host certs since we'll manage them at run time

WORKDIR $WDIR

RUN sudo yum install -y git jq python3-devel python3-pip && sudo yum update -y && sudo yum clean all && sudo rm -rf /var/cache/yum && sudo pip3 install --upgrade pip && sudo pip3 install --upgrade setuptools && sudo pip3 install python-openstackclient && sudo pip3 install python-manilaclient

# Install latest kubectl
RUN curl -k -L -O https://dl.google.com/go/go1.17.3.linux-amd64.tar.gz && tar xfz go1.17.3.linux-amd64.tar.gz && rm go1.17.3.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${PATH}:${GOROOT}/bin:${WDIR}"
RUN git clone https://github.com/dmwm/cmsweb-exporters.git

WORKDIR $WDIR/cmsweb-exporters/openstack
RUN go mod tidy && go build quota_exporter.go && cp quota_exporter $WDIR && cp quota.sh $WDIR

WORKDIR $WDIR
