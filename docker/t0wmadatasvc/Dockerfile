FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250716-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=2.1.1

# Start Workaround missing WMCore deps. (this could be removed later, when T0 found out way to included WMCore as their t0wmadatasvc package deps.
ARG WMCORE_VERSION=2.4.1
RUN sudo apt update -y && sudo apt install -y \
  build-essential \
  libmariadb-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN pip install wmcore==$WMCORE_VERSION
# End Workaround

RUN pip install git+https://github.com/dmwm/t0wmadatasvc.git@$TAG
ENV WDIR=/data
ENV USER=_t0wmadatasvc
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Hardcode fix missing config.py, overwrite run.sh
COPY run.sh /data/run.sh
COPY config.py /data/config.py

USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
