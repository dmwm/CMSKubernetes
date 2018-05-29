FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=exporters

RUN yum update -y && yum clean all
RUN yum install -y git-core krb5-devel readline-devel openssl
RUN yum clean all

# Create new user account
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR/bin
WORKDIR ${WDIR}

# install cmsweb backend which brings extra libraries, such as curl
# we need to set them up to have proper environment
ADD install.sh $WDIR/install.sh
RUN $WDIR/install.sh

# get go dependencies
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
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
RUN go build reqmgr_exporter.go
RUN cp reqmgr_exporter $WDIR/bin
ENV PATH="${GOPATH}/src/github.com/vkuznet/cmsweb-exporters:${GOPATH}/src/github.com/vkuznet/cmsweb-exporters/bin:${PATH}"

# add proxy generation via robot certificate
RUN echo "3 */3 * * * /data/proxy.sh $USER 2>&1 1>& /dev/null" | crontab -
ENV X509_USER_PROXY=/data/srv/current/auth/proxy/proxy

# run the service
ADD proxy.sh $WDIR/proxy.sh
ADD run.sh $WDIR/run.sh
ADD probe.sh $WDIR/probe.sh
WORKDIR ${WDIR}
CMD ["run.sh"]
