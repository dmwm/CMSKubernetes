FROM cmssw/cmsweb:20210706-withoutexporter as web-builder
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
RUN $WDIR/install.sh &&  crontab -l > /data/crontab.txt

# build apache exporter
# RUN mkdir -p /data/gopath/bin
# ENV GOPATH /data/gopath
# RUN go get github.com/Lusitaniae/apache_exporter && crontab -l > /data/crontab.txt

# RUN wget https://github.com/Lusitaniae/apache_exporter/releases/download/v0.9.0/apache_exporter-0.9.0.linux-amd64.tar.gz && tar -xvzf apache_exporter-0.9.0.linux-amd64.tar.gz --directory /data/gopath && cp /data/gopath/apache_exporter-0.9.0.linux-amd64/apache_exporter /data/gopath/bin && crontab -l > /data/crontab.txt 

# extract relevant pieces from web-builder
FROM cmssw/cmsweb-base:20210706
ENV WDIR=/data
ENV USER=_frontend
ADD logstash.repo /etc/yum.repos.d/logstash.repo
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && yum install -y perl filebeat python-pip && yum clean all && rm -rf /var/cache/yum && pip install requests && useradd ${USER} && install -o ${USER} -d ${WDIR} && echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
COPY --chown=_frontend:_frontend --from=web-builder /data /data
RUN crontab /data/crontab.txt

# run the service
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh

# ENV PATH="${WDIR}/cmsweb/bin:${WDIR}:${WDIR}/gopath/bin:${PATH}"
ENV PATH="${WDIR}/cmsweb/bin:${WDIR}:${PATH}"

WORKDIR $WDIR
CMD ["./run.sh"]
