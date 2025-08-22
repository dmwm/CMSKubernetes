FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250716-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=2.1.1

# Start Workaround missing WMCore deps. (this could be removed later, when T0 found out way to included WMCore as their t0wmadatasvc package deps.
ARG WMCORE_VERSION=2.4.1
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
RUN pip install wmcore==$WMCORE_VERSION
# End Workaround

# Sanity checks: show exactly what's missing
RUN ldd /opt/oracle/instantclient/libclntsh.so.21.1 || true
RUN python - <<'PY' || true
import oracledb
print("Driver version:", oracledb.__version__)
try:
    oracledb.init_oracle_client(lib_dir="/opt/oracle/instantclient")
    print("Thick init OK")
except Exception as e:
    print("Init failed:", e)
PY

RUN pip install git+https://github.com/dmwm/t0wmadatasvc.git@$TAG
ENV WDIR=/data

# Hardcode fix missing config.py, overwrite run.sh
COPY ./config.py $WDIR/config.py
COPY ./run.sh $WDIR/run.sh

ENV USER=_t0wmadatasvc
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
