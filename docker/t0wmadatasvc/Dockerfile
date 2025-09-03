FROM registry.cern.ch/cmsweb/cmsweb:20250311-stable AS cmsweb

FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250716-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=2.1.1
ARG WMCORE_VERSION=2.4.1

### Begin fixes of missing C/C++ OracleDB Thick mode run-time libs/deps.
COPY --from=cmsweb /etc/tnsnames.ora /etc/tnsnames.ora
RUN sudo apt update -y && sudo apt install -y \
  build-essential \
  libmariadb-dev \
  unzip curl libaio1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# Download and Install Oracle Client for thick mode connection.
RUN curl -fsSL -o /tmp/instantclient.zip \
    https://download.oracle.com/otn_software/linux/instantclient/219000/instantclient-basiclite-linux.x64-21.9.0.0.0dbru.zip && \
    unzip /tmp/instantclient.zip -d /opt/oracle && \
    rm /tmp/instantclient.zip && \
    ln -s /opt/oracle/instantclient_* /opt/oracle/instantclient
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
### End Fixing

RUN pip install wmcore==$WMCORE_VERSION
RUN pip install git+https://github.com/dmwm/t0wmadatasvc.git@$TAG

ENV WDIR=/data
ENV USER=_t0wmadatasvc
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
