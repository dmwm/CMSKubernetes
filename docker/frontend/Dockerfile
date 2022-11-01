
FROM registry.cern.ch/cmsweb/cmsweb:20221020-stable as web-builder
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
RUN mkdir -p /data/gopath/bin
ENV GOPATH /data/gopath
# RUN go get github.com/Lusitaniae/apache_exporter && crontab -l > /data/crontab.txt

RUN wget https://github.com/Lusitaniae/apache_exporter/releases/download/v0.9.0/apache_exporter-0.9.0.linux-amd64.tar.gz && tar -xvzf apache_exporter-0.9.0.linux-amd64.tar.gz --directory /data/gopath && cp /data/gopath/apache_exporter-0.9.0.linux-amd64/apache_exporter /data/gopath/bin && crontab -l > /data/crontab.txt 


# extract relevant pieces from web-builder
FROM registry.cern.ch/cmsweb/cmsweb-base:20220601-stable
ENV WDIR=/data
ENV USER=_frontend
ADD logstash.repo /etc/yum.repos.d/logstash.repo
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && yum install -y perl filebeat python-pip && yum clean all && rm -rf /var/cache/yum && pip install requests==2.27.1 certifi==2020.4.5.1 && useradd ${USER} && install -o ${USER} -d ${WDIR} && echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#Get alert manager
RUN curl -ksLO https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz
RUN tar xfz alertmanager-0.24.0.linux-amd64.tar.gz && mv alertmanager-0.24.0.linux-amd64/amtool $WDIR/ && rm -rf alertmanager-0.24.0.linux-amd64*

USER ${USER}
COPY --chown=_frontend:_frontend --from=web-builder /data /data
RUN crontab /data/crontab.txt


# run the service
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
ADD alerts.sh $WDIR/alerts.sh

ENV PATH="${WDIR}/cmsweb/bin:${WDIR}:${WDIR}/gopath/bin:${PATH}"

WORKDIR $WDIR
CMD ["./run.sh"]
