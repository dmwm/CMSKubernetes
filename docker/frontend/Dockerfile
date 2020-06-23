FROM cmssw/cmsweb:20200531 as web-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_frontend

# create bashs link to bash
# RUN ln -s /bin/bash /usr/bin/bashs
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# add fake host certs since we'll manage them at run time
RUN mkdir -p /data/certs
RUN echo "bla" > /data/certs/hostcert.pem
RUN echo "bla" > /data/certs/hostkey.pem
RUN chmod 0600 /data/certs/hostkey.pem

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# pass env variable to the build
ARG CMSK8S
ENV CMSK8S=$CMSK8S
ARG CMSWEB_ENV
ENV CMSWEB_ENV=$CMSWEB_ENV

# install
ADD install.sh $WDIR/install.sh
RUN $WDIR/install.sh

# build apache exporter
RUN mkdir /data/gopath
ENV GOPATH /data/gopath
RUN go get github.com/Lusitaniae/apache_exporter

# extract relevant pieces from web-builder
FROM cern/cc7-base:20200531-2.x86_64
ENV WDIR=/data
ENV USER=_frontend
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo /etc/yum.repos.d/egi.repo
ADD http://linuxsoft.cern.ch/wlcg/wlcg-centos7.repo /etc/yum.repos.d/wlcg-centos7.repo
ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
ADD logstash.repo /etc/yum.repos.d/logstash.repo
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
RUN yum install -y sudo perl cern-get-certificate fetch-crl \
    CERN-CA-certs ca-certificates dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
    ca_EG-GRID ca_CERN-GridCA ca_CERN-LCG-IOTA-CA ca_CERN-Root-2 filebeat
RUN ln -s /bin/bash /usr/bin/bashs
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# add fetch-crl to fetch all sertificates
RUN echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360" > /etc/cron.d/fetch-crl-docker
USER ${USER}
COPY --chown=_frontend:_frontend --from=web-builder /data /data

# run the service
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
ENV PATH="${WDIR}/cmsweb/bin:${WDIR}:${WDIR}/gopath/bin:${PATH}"
WORKDIR $WDIR
CMD ["./run.sh"]
