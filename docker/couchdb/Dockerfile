FROM couchdb:3.2.2
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN apt-get update && apt-get install -y vim less sudo wget unzip python pip
RUN pip install CMSCouchapp

ENV WDIR=/data
ENV USER=_couchdb

RUN mkdir -p /etc/grid-security

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# pass env variable to the build
ARG CMSK8S
ENV CMSK8S=$CMSK8S
ARG COUCH_USER
ENV COUCH_USER=$COUCH_USER
ARG COUCH_PASS
ENV COUCH_PASS=$COUCH_PASS

# get binary build of couchdb exporter
RUN curl -ksLO https://github.com/gesellix/couchdb-prometheus-exporter/releases/download/v27.0.0/couchdb-prometheus-exporter_27.0.0_Linux_x86_64.tar.gz
RUN tar xfz couchdb-prometheus-exporter_27.0.0_Linux_x86_64.tar.gz
RUN rm couchdb-prometheus-exporter_27.0.0_Linux_x86_64.tar.gz LICENSE README*.md
ENV PATH="${WDIR}:${PATH}"

# add necessary scripts
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh

# add /data/srv
RUN mkdir -p /data/srv/current/config/couchdb \
    && mkdir -p /data/srv/logs/couchdb \
    && mkdir -p /data/srv/state/couchdb/stagingarea \
    && mkdir -p /data/srv/state/couchdb/database \
    && mkdir -p /data/srv/current/auth/couchdb \
    && mkdir -p /data/srv/current/apps/couchdb/etc/profile.d/ \
    && touch /data/srv/current/apps/couchdb/etc/profile.d/init.sh \
    && ln -s /etc/secrets/couch_creds /data/srv/current/auth/couchdb/couch_creds \
    && ln -s /etc/secrets/local.ini /data/srv/current/config/couchdb/local.ini
ADD manage /data/srv/current/config/couchdb/manage
ADD couchdb-logrotate.conf /data/srv/current/config/couchdb/couchdb-logrotate.conf

ENV PATH="/opt/couchdb/bin:/usr/local/bin/:${PATH}"

# setup final environment
USER $USER
WORKDIR $WDIR
CMD ["./run.sh"]
