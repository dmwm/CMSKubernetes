ARG MDB_TAG=10.6.5
FROM mariadb:$MDB_TAG
MAINTAINER Todor Ivanov todor.ivanov@cern.ch

ARG MDB_TAG
ENV MDB_TAG=$MDB_TAG
RUN echo MDB_TAG=$MDB_TAG

RUN apt-get update && apt-get install -y vim less sudo wget unzip python3 pip \
    hostname net-tools iputils-ping procps emacs-nox tcpdump && apt-get clean

# ENV MDB_PORT=
ENV MDB_ROOT_DIR=/data

ENV MDB_BASE_DIR=$MDB_ROOT_DIR/srv/mariadb
ENV MDB_ADMIN_DIR=$MDB_ROOT_DIR/admin/mariadb
ENV WMA_ADMIN_DIR=$MDB_ROOT_DIR/admin/wmagent
ENV MDB_CERTS_DIR=$MDB_ROOT_DIR/certs

ENV MDB_CURRENT_DIR=$MDB_BASE_DIR/$MDB_TAG
ENV MDB_MANAGE_DIR=$MDB_CURRENT_DIR
ENV MDB_AUTH_DIR=$MDB_CURRENT_DIR/auth/
ENV MDB_INSTALL_DIR=$MDB_CURRENT_DIR/install
ENV MDB_STATE_DIR=$MDB_CURRENT_DIR/state
ENV MDB_DATABASE_DIR=$MDB_INSTALL_DIR/database
ENV MDB_CONFIG_DIR=$MDB_CURRENT_DIR/config
ENV MDB_LOG_DIR=$MDB_CURRENT_DIR/logs
ENV MDB_DEPLOY_DIR=/usr/local
ENV MDB_ENV_FILE=$MDB_DEPLOY_DIR/deploy/env.sh
ENV MDB_SOCKET_FILE=/var/run/mysqld/mariadb.sock
ENV MDB_SECRETS_FILE=$MDB_ADMIN_DIR/MariaDB.secrets
ENV WMA_SECRETS_FILE=$WMA_ADMIN_DIR/WMAgent.secrets
ENV WMA_DATABASE=wmagent

# start the setup
RUN mkdir -p $MDB_ROOT_DIR $MDB_CURRENT_DIR $MDB_CONFIG_DIR $MDB_MANAGE_DIR \
    $MDB_LOG_DIR $MDB_DATABASE_DIR $MDB_STATE_DIR $MDB_AUTH_DIR
RUN ln -s $MDB_CURRENT_DIR $MDB_BASE_DIR/current

# add necessary scripts
ADD run.sh ${MDB_ROOT_DIR}/
ADD manage ${MDB_MANAGE_DIR}/manage
RUN ln -s ${MDB_MANAGE_DIR}/manage ${MDB_ROOT_DIR}/manage

# The $MDB_CONFIG_DIR is NOT to be mounted from the host
# and the my.cnf file is going to be accessible only from the container
ADD my.cnf ${MDB_CONFIG_DIR}/my.cnf

ENV PATH="/usr/local/bin/:${MDB_ROOT_DIR}:${PATH}"

# Set command prompt for root
RUN <<EOF cat >> /root/.bashrc
export PS1="(MariaDB-$MDB_TAG) [\u@\h:\W]# "
EOF

# allow dynamic users to create homefolders and .bashrc
RUN chmod 777 /home

# setup final environment
WORKDIR $MDB_ROOT_DIR
ENTRYPOINT ["./run.sh", "2>&1"]
