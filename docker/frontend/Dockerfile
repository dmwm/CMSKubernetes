FROM cmssw/cmsweb:20210315 as web-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_frontend

# create bashs link to bash
# RUN ln -s /bin/bash /usr/bin/bashs
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR} && echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# add fake host certs since we'll manage them at run time
RUN mkdir -p /data/certs && echo "bla" > /data/certs/hostcert.pem && echo "bla" > /data/certs/hostkey.pem && chmod 0600 /data/certs/hostkey.pem && mkdir -p $WDIR
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
RUN go get github.com/Lusitaniae/apache_exporter && crontab -l > /data/crontab.txt

# extract relevant pieces from web-builder
FROM cmssw/cmsweb-base:20210315
ENV WDIR=/data
ENV USER=_frontend
ADD logstash.repo /etc/yum.repos.d/logstash.repo
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && yum install -y perl filebeat && yum clean all && rm -rf /var/cache/yum && useradd ${USER} && install -o ${USER} -d ${WDIR} && echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
COPY --chown=_frontend:_frontend --from=web-builder /data /data
RUN crontab /data/crontab.txt

# run the service
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
ENV PATH="${WDIR}/cmsweb/bin:${WDIR}:${WDIR}/gopath/bin:${PATH}"
WORKDIR $WDIR
CMD ["./run.sh"]
