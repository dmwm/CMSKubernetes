FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230525
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y libmariadb-dev-compat libmariadb-dev apache2-utils sudo

# WMA_TAG to be passed at build time through `--build-arg WMA_TAG=<WMA_TAG>`. Default: None
ARG WMA_TAG=None
ENV WMA_TAG=${WMA_TAG}
ENV WMA_USER=cmst1
ENV WMA_GROUP=zh
ENV WMA_UID=31961
ENV WMA_GID=1399
ENV WDIR=/data

# RUN groupadd -g ${WMA_GID} ${WMA_GROUP}
RUN useradd ${WMA_USER}
RUN install -o ${WMA_USER} -g ${WMA_GID} -d ${WDIR}

# RUN useradd -u ${WMA_UID} -g ${WMA_GID} ${WMA_USER}
# && install -o ${WMA_USER} -g {WMA_GID} -d ${WDIR}
RUN echo "%${WMA_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add install script
ADD install.sh ${WDIR}/install.sh

# Add wmagent run script
ADD run.sh ${WDIR}/run.sh

RUN chown ${WMA_USER} ${WDIR}/run.sh ${WDIR}/install.sh

WORKDIR ${WDIR}
USER ${WMA_USER}

# Install the requested WMA_TAG.
RUN ${WDIR}/install.sh ${WMA_TAG}

# Define the entrypoint. All the run.sh paramters should be passed at runtime.
# ENTRYPOINT ["${WDIR}/run.sh"]
ENTRYPOINT ["/bin/bash", "-l"]
