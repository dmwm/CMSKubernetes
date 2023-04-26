FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230525
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# Install basic OS package dependencies
RUN apt-get update
RUN apt-get install -y libmariadb-dev-compat libmariadb-dev apache2-utils hostname net-tools iputils-ping

# WMA_TAG to be passed at build time through `--build-arg WMA_TAG=<WMA_TAG>`. Default: None
ARG WMA_TAG=None
ENV WMA_TAG=${WMA_TAG}
ENV WMA_USER=cmst1
ENV WMA_GROUP=zh
ENV WMA_UID=31961
ENV WMA_GID=1399
ENV WMA_ROOT_DIR=/data

# Basic WMAgent directory structure passed to all scripts through env variables:
# NOTE: Those should be static and depend only on $WMA_BASE_DIR
ENV BASE_DIR=$WMA_ROOT_DIR/srv
ENV ADMIN_DIR=$WMA_ROOT_DIR/admin/wmagent
ENV CERTS_DIR=$WMA_ROOT_DIR/certs

ENV DEPLOY_DIR=$BASE_DIR/wmagent/$WMA_TAG
ENV CURRENT_DIR=$BASE_DIR/wmagent/current
ENV INSTALL_DIR=$CURRENT_DIR/install
ENV CONFIG_DIR=$CURRENT_DIR/config
ENV MANAGE_DIR=$CONFIG_DIR/wmagent
ENV ENV_FILE=$ADMIN_DIR/env.sh

# Setting up users and previleges
RUN groupadd -g ${WMA_GID} ${WMA_GROUP}
RUN useradd -u ${WMA_UID} -g ${WMA_GID} -m ${WMA_USER}
RUN install -o ${WMA_USER} -g ${WMA_GID} -d ${WMA_ROOT_DIR}

# Add WMA_USER to sudoers
RUN echo "${WMA_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add install script
ADD install.sh ${WMA_ROOT_DIR}/install.sh

# Add wmagent run script
ADD run.sh ${WMA_ROOT_DIR}/run.sh

# Install the requested WMA_TAG.
RUN ${WMA_ROOT_DIR}/install.sh -v ${WMA_TAG}
RUN chown -R ${WMA_USER}:${WMA_GID} ${WMA_ROOT_DIR}

# Switch to the runtime directory and user
WORKDIR ${WMA_ROOT_DIR}
USER ${WMA_USER}

# Define the entrypoint. All the run.sh paramters should be passed at runtime.
ENTRYPOINT ["./run.sh"]
