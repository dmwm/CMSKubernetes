FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230525
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y libmariadb-dev-compat libmariadb-dev apache2-utils hostname sudo

# WMA_TAG to be passed at build time through `--build-arg WMA_TAG=<WMA_TAG>`. Default: None
ARG WMA_TAG=None
ENV WMA_TAG=${WMA_TAG}
ENV WMA_USER=cmst1
ENV WMA_GROUP=zh
ENV WMA_UID=31961
ENV WMA_GID=1399
ENV WMA_BASE_DIR=/data
# ENV WMA_DEPLOY_DIR=/data/srv/wmagent

RUN groupadd -g ${WMA_GID} ${WMA_GROUP}
RUN useradd -u ${WMA_UID} -g ${WMA_GID} ${WMA_USER}
RUN install -o ${WMA_USER} -g ${WMA_GID} -d ${WMA_BASE_DIR}

# RUN useradd -u ${WMA_UID} -g ${WMA_GID} ${WMA_USER}
# && install -o ${WMA_USER} -g {WMA_GID} -d ${WMA_BASE_DIR}
RUN echo "%${WMA_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add install script
ADD install.sh ${WMA_BASE_DIR}/install.sh

# Add wmagent run script
ADD run.sh ${WMA_BASE_DIR}/run.sh

# Install the requested WMA_TAG.
RUN ${WMA_BASE_DIR}/install.sh ${WMA_TAG}
RUN chown -R ${WMA_USER}:${WMA_GID} ${WMA_BASE_DIR}
# RUN chown -R ${WMA_USER} ${WMA_BASE_DIR}/run.sh ${WMA_BASE_DIR}/install.sh

WORKDIR ${WMA_BASE_DIR}
USER ${WMA_USER}

# Define the entrypoint. All the run.sh paramters should be passed at runtime.
ENTRYPOINT ["./run.sh"]
