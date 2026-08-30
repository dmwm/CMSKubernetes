ARG TAG=3.2.2
FROM couchdb:${TAG}
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ARG TAG
ENV TAG=${TAG}
RUN echo TAG=$TAG

RUN apt-get update && apt-get install -y vim less sudo wget unzip python3 pip

# # Install some debugging tools
RUN apt-get install -y hostname net-tools iputils-ping procps emacs-nox tcpdump && apt-get clean

# Install recursive ps utility tool
RUN apt-get install -y pslist && apt-get clean

# RUN pip install CMSCouchapp
# when we install CMSCouchapp on Debian system it fails with PEP 668 error
# which prevents installing external (Python packages from pip) on Debian system
# there are two ways to resolve it:
# - option A: install with (potential) break of system packages
#   RUN pip install --break-system-packages CMSCouchapp
# - option B: install in virtual environment
RUN apt install -y python3.11-venv
RUN python3 -m venv /data/venv
ENV PATH="/data/venv/bin:$PATH"
RUN pip install --no-cache-dir CMSCouchapp

ENV COUCH_PORT=5984
ENV COUCH_ROOT_DIR=/data

ENV COUCH_BASE_DIR=$COUCH_ROOT_DIR/srv/couchdb
ENV COUCH_ADMIN_DIR=$COUCH_ROOT_DIR/admin/couchdb
ENV WMA_ADMIN_DIR=$COUCH_ROOT_DIR/admin/wmagent
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
ENV COUCH_SECRETS_FILE=$COUCH_ADMIN_DIR/CouchDB.secrets
ENV WMA_SECRETS_FILE=$WMA_ADMIN_DIR/WMAgent.secrets


# RUN mkdir -p /etc/grid-security

# start the setup
RUN mkdir -p $COUCH_ROOT_DIR

ENV PATH="${COUCH_ROOT_DIR}:${PATH}"

RUN mkdir -p $COUCH_CURRENT_DIR $COUCH_CONFIG_DIR $COUCH_MANAGE_DIR $COUCH_LOG_DIR $COUCH_DATABASE_DIR $COUCH_STATE_DIR $COUCH_AUTH_DIR
RUN ln -s $COUCH_CURRENT_DIR $COUCH_BASE_DIR/current

# add necessary scripts
ADD run.sh ${COUCH_ROOT_DIR}/
ADD manage ${COUCH_MANAGE_DIR}/manage
RUN ln -s ${COUCH_MANAGE_DIR}/manage ${COUCH_ROOT_DIR}/manage

# The $COUCH_CONFIG_DIR is to be mounted from the host and locla.ini read from there
ADD local.ini ${COUCH_DEPLOY_DIR}/local.ini
RUN ln -s ${COUCH_CONFIG_DIR}/local.ini /opt/couchdb/etc/local.d/

ENV PATH="/opt/couchdb/bin:/usr/local/bin/:${PATH}"
ENV CRYPTOGRAPHY_ALLOW_OPENSSL_102=true

# Set command prompt for root
RUN <<EOF cat >> /root/.bashrc
export PS1="(CouchDB-$TAG) [\u@\h:\W]# "
EOF

# allow dynamic users to create homefolders and .bashrc
RUN chmod 777 /home

# setup final environment
WORKDIR $COUCH_ROOT_DIR
ENTRYPOINT ["./run.sh"]
