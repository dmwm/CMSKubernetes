ARG TAG=3.2.2
FROM couchdb:${TAG}
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ARG TAG
ENV TAG=${TAG}
RUN echo TAG=$TAG

RUN apt-get update && apt-get install -y vim less sudo wget unzip python pip

# # Install some debugging tools
RUN apt-get install -y hostname net-tools iputils-ping procps emacs-nox tcpdump && apt-get clean

RUN pip install CMSCouchapp

# ENV USER=couchdb
# ENV GROUP=couchdb
ENV USER=cmst1
ENV GROUP=zh
ENV COUCH_UID=31961
ENV COUCH_GID=1399
ENV COUCH_PORT=5984
# ENV COUCH_UID=5984
# ENV COUCH_GID=5984

ENV COUCH_ROOT_DIR=/data

ENV COUCH_BASE_DIR=$COUCH_ROOT_DIR/srv/couchdb
ENV COUCH_ADMIN_DIR=$COUCH_ROOT_DIR/admin/wmagent
ENV COUCH_CERTS_DIR=$COUCH_ROOT_DIR/certs

ENV COUCH_CURRENT_DIR=$COUCH_BASE_DIR/$TAG
ENV COUCH_MANAGE_DIR=$COUCH_CURRENT_DIR
ENV COUCH_AUTH_DIR=$COUCH_BASE_DIR/auth/
ENV COUCH_INSTALL_DIR=$COUCH_CURRENT_DIR/install
ENV COUCH_STATE_DIR=$COUCH_CURRENT_DIR/state
ENV COUCH_DATABASE_DIR=$COUCH_INSTALL_DIR/database
ENV COUCH_CONFIG_DIR=$COUCH_CURRENT_DIR/config
ENV COUCH_LOG_DIR=$COUCH_CURRENT_DIR/logs
ENV COUCH_DEPLOY_DIR=/usr/local
ENV COUCH_ENV_FILE=$COUCH_DEPLOY_DIR/deploy/env.sh


# RUN mkdir -p /etc/grid-security

# # Setting up users and previleges
# # THIS MUST HAPPEN MANUALLY ON THE HOST:
RUN groupadd -g ${COUCH_GID} ${GROUP}
RUN useradd -u ${COUCH_UID} -g ${COUCH_GID} -m ${USER}
RUN install -o ${USER} -g ${COUCH_GID} -d ${COUCH_ROOT_DIR}


# add user to sudoers file
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# start the setup
RUN mkdir -p $COUCH_ROOT_DIR

ENV PATH="${COUCH_ROOT_DIR}:${PATH}"

RUN mkdir -p $COUCH_CURRENT_DIR $COUCH_CONFIG_DIR $COUCH_MANAGE_DIR $COUCH_LOG_DIR $COUCH_DATABASE_DIR $COUCH_STATE_DIR $COUCH_AUTH_DIR
RUN ln -s $COUCH_CURRENT_DIR $COUCH_BASE_DIR/current

# ENV COUCHDB_USER=admin
# ENV COUCHDB_PASSWORD=adminpass

# add necessary scripts
ADD run.sh ${COUCH_ROOT_DIR}/
ADD manage ${COUCH_MANAGE_DIR}/manage
RUN ln -s ${COUCH_MANAGE_DIR}/manage ${COUCH_ROOT_DIR}/manage

# The $COUCH_CONFIG_DIR is to be mounted from the host and locla.ini read from there
# ADD local.ini ${COUCH_CONFIG_DIR}/local.ini
RUN ln -s ${COUCH_CONFIG_DIR}/local.ini /opt/couchdb/etc/local.d/

ENV PATH="/opt/couchdb/bin:/usr/local/bin/:${PATH}"
ENV CRYPTOGRAPHY_ALLOW_OPENSSL_102=true

# RUN <<EOF cat >> /opt/couchdb/.bashrc
RUN <<EOF cat >> /home/$USER/.bashrc

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -la --color=auto'

alias manage=$COUCH_MANAGE_DIR/manage

# set CouchDB docker specific bash prompt:
export PS1="(CouchDB-$TAG) [\u@\h:\W]\$ "
EOF

RUN chown -R ${USER}:${GROUP} ${COUCH_ROOT_DIR}

# setup final environment
USER $USER
WORKDIR $COUCH_ROOT_DIR
ENTRYPOINT ["./run.sh"]
