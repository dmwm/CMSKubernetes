ARG TAG=11.0
ARG MDB_TAG=$TAG
FROM mariadb:${MDB_TAG}
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ARG MDB_TAG=$TAG
ENV MDB_TAG=${MDB_TAG}
RUN echo MDB_TAG=$MDB_TAG

RUN apt-get update && apt-get install -y vim less sudo wget unzip python3 pip

# # Install some debugging tools
RUN apt-get install -y hostname net-tools iputils-ping procps emacs-nox tcpdump && apt-get clean

ENV USER=cmst1
# ENV MARIADB_PORT=
ENV UID=31961
ENV MARIADB_ROOT_DIR=/data

ENV MARIADB_BASE_DIR=$MARIADB_ROOT_DIR/srv/mariadb
ENV MARIADB_ADMIN_DIR=$MARIADB_ROOT_DIR/admin/wmagent
ENV MARIADB_CERTS_DIR=$MARIADB_ROOT_DIR/certs

ENV MARIADB_CURRENT_DIR=$MARIADB_BASE_DIR/$MDB_TAG
ENV MARIADB_MANAGE_DIR=$MARIADB_CURRENT_DIR
ENV MARIADB_AUTH_DIR=$MARIADB_CURRENT_DIR/auth/
ENV MARIADB_INSTALL_DIR=$MARIADB_CURRENT_DIR/install
ENV MARIADB_STATE_DIR=$MARIADB_CURRENT_DIR/state
ENV MARIADB_DATABASE_DIR=$MARIADB_INSTALL_DIR/database
ENV MARIADB_CONFIG_DIR=$MARIADB_CURRENT_DIR/config
ENV MARIADB_LOG_DIR=$MARIADB_CURRENT_DIR/logs
ENV MARIADB_DEPLOY_DIR=/usr/local
ENV MARIADB_ENV_FILE=$MARIADB_DEPLOY_DIR/deploy/env.sh
ENV MARIADB_SECRETS_FILE=$MARIADB_ADMIN_DIR/MariaDB.secrets


RUN useradd -u $UID -m $USER

# add user to sudoers file
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# start the setup
RUN mkdir -p $MARIADB_ROOT_DIR

ENV PATH="${MARIADB_ROOT_DIR}:${PATH}"

RUN mkdir -p $MARIADB_CURRENT_DIR $MARIADB_CONFIG_DIR $MARIADB_MANAGE_DIR $MARIADB_LOG_DIR $MARIADB_DATABASE_DIR $MARIADB_STATE_DIR $MARIADB_AUTH_DIR
RUN ln -s $MARIADB_CURRENT_DIR $MARIADB_BASE_DIR/current

# add necessary scripts
ADD run.sh ${MARIADB_ROOT_DIR}/
ADD start-mysql.sh ${MARIADB_ROOT_DIR}/
ADD manage ${MARIADB_MANAGE_DIR}/manage
RUN ln -s ${MARIADB_MANAGE_DIR}/manage ${MARIADB_ROOT_DIR}/manage

# The $MARIADB_CONFIG_DIR is to be mounted from the host and my.cnf read from there
ADD my.cnf ${MARIADB_CONFIG_DIR}/my.cnf
# RUN ln -s ${MARIADB_CONFIG_DIR}/my.cnf /opt/mariadb/etc/local.d/
# ADD my.cnf /etc/mysql/my.cnf


ENV PATH="/opt/couchdb/bin:/usr/local/bin/:${PATH}"

RUN <<EOF cat >> /home/${USER}/.bashrc

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -la --color=auto'

alias manage=$MARIADB_MANAGE_DIR/manage

# set MariaDB docker specific bash prompt:
export PS1="(MariaDB-$MDB_TAG) [\u@\h:\W]\$ "
EOF

RUN chown -R ${USER} ${MARIADB_ROOT_DIR}

# setup final environment
USER $USER
WORKDIR $MARIADB_ROOT_DIR
ENTRYPOINT ["./run.sh"]
