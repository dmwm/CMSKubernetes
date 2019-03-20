FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=sw
ADD install.sh $WDIR/install.sh

RUN yum update -y && yum clean all

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# install
RUN $WDIR/install.sh

# build couchdb exporter
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/golang/glog
RUN go get github.com/namsral/flag
RUN go get github.com/gesellix/couchdb-prometheus-exporter/glogadapt
RUN go get github.com/gesellix/couchdb-prometheus-exporter/lib
RUN go get github.com/gesellix/couchdb-prometheus-exporter

# add necessary scripts
ADD run.sh $WDIR/run.sh
ADD proxy.sh $WDIR/proxy.sh
ADD monitor.sh $WDIR/monitor.sh

# setup final environment
USER $USER
WORKDIR $WDIR
CMD ["./run.sh"]
