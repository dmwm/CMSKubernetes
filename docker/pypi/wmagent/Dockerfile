# syntax=docker/dockerfile-upstream:master
FROM registry.cern.ch/cmsweb/wmagent-base:pypi-20240604
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# TAG to be passed at build time through `--build-arg TAG=<WMA_TAG>`. Default: None
ARG TAG=None
ARG WMA_TAG=$TAG
ENV WMA_TAG=$WMA_TAG
ENV WMA_ROOT_DIR=/data

# Parsing the WMA_TAG in parts step by step
ENV WMA_VER_MINOR=${WMA_TAG#*.*.}
ENV WMA_VER_MAJOR=${WMA_TAG%.$WMA_VER_MINOR}
ENV WMA_VER_MINOR=${WMA_VER_MINOR%rc*}
ENV WMA_VER_MINOR=${WMA_VER_MINOR%.*}
ENV WMA_VER_RELEASE=${WMA_VER_MAJOR}.${WMA_VER_MINOR}
ENV WMA_VER_PATCH=${WMA_TAG#$WMA_VER_RELEASE}
ENV WMA_VER_PATCH=${WMA_VER_PATCH#.}

# Basic WMAgent directory structure passed to all scripts through env variables:
# NOTE: Those should be static and depend only on $WMA_BASE_DIR
ENV WMA_BASE_DIR=$WMA_ROOT_DIR/srv/wmagent
ENV WMA_ADMIN_DIR=$WMA_ROOT_DIR/admin/wmagent
ENV WMA_CERTS_DIR=$WMA_ROOT_DIR/certs

# ENV WMA_HOSTADMIN_DIR=$WMA_ADMIN_DIR/hostadmin
ENV WMA_CURRENT_DIR=$WMA_BASE_DIR/$WMA_VER_RELEASE
ENV WMA_AUTH_DIR=$WMA_CURRENT_DIR/auth/
ENV WMA_INSTALL_DIR=$WMA_CURRENT_DIR/install
ENV WMA_STATE_DIR=$WMA_CURRENT_DIR/state
ENV WMA_CONFIG_DIR=$WMA_CURRENT_DIR/config
ENV WMA_CONFIG_FILE=$WMA_CONFIG_DIR/config.py
ENV WMA_LOG_DIR=$WMA_CURRENT_DIR/logs
ENV WMA_DEPLOY_DIR=/usr/local
ENV WMA_MANAGE_DIR=$WMA_DEPLOY_DIR/bin
ENV WMA_ENV_FILE=$WMA_DEPLOY_DIR/deploy/env.sh
ENV WMA_SECRETS_FILE=$WMA_ADMIN_DIR/WMAgent.secrets
ENV ORACLE_PATH=$WMA_DEPLOY_DIR/etc/oracle

# Add all deployment needed directories
ADD bin $WMA_DEPLOY_DIR/bin
ADD etc $WMA_DEPLOY_DIR/etc

# Add install script
ADD install.sh ${WMA_ROOT_DIR}/install.sh

# Add wmagent run script
ADD run.sh ${WMA_ROOT_DIR}/run.sh
ADD init.sh ${WMA_ROOT_DIR}/init.sh

# Install the requested WMA_TAG.
RUN ${WMA_ROOT_DIR}/install.sh -t ${WMA_TAG}

# Switch to the runtime directory
WORKDIR ${WMA_ROOT_DIR}

# Set command prompt for root
RUN <<EOF cat >> /root/.bashrc
export PS1="(WMAgent-\$WMA_TAG) [\u@\h:\W]# "
EOF

# allow dynamic users to create homefolders and .bashrc
RUN chmod 777 /home

# preserve the whole env for later use by the cron daemon
RUN env > /etc/environment

# Define the entrypoint (Using exec form):
ENTRYPOINT ["./run.sh", "2>&1"]
