FROM cmssw/cmsweb:20201113
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# add environment
ENV WDIR=/data
ENV USER=_cmsmon

RUN yum install -y git-core krb5-devel readline-devel openssl autoconf automake libtool make gcc gcc-c++ unzip
RUN yum clean all

# Create new user account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# download golang and install it
ENV GOPATH=$WDIR/gopath
RUN mkdir $WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# pass env variable to the build
ARG CMSK8S
ENV CMSK8S=$CMSK8S

# install Go dependencies
RUN go get github.com/sirupsen/logrus
RUN go get github.com/shirou/gopsutil

# build cmsmon
WORKDIR ${WDIR}
RUN git clone https://github.com/vkuznet/cmsmon.git
WORKDIR $WDIR/cmsmon
RUN make
ENV PATH="${WDIR}/cmsmon:${PATH}"

# add scripts to run and configuration
ADD run.sh $WDIR/run.sh
ADD config.json $WDIR/config.json

# run the service
WORKDIR ${WDIR}
RUN cat $WDIR/config.json | sed -e "s,GOPATH,$GOPATH,g" > $WDIR/cmsmon-config.json
CMD ["run.sh"]
