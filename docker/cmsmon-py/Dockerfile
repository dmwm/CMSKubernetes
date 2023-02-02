FROM gitlab-registry.cern.ch/linuxsupport/cc7-base:latest
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

# Should be full such that includes minor version
ARG PY_VERSION=3.9.13
ARG CMSMONITORING_TAG=0.0.0
ENV WDIR=/data

ENV PYTHONPATH="${PYTHONPATH}:${WDIR}:${WDIR}/CMSMonitoring/src/python"
ENV LC_ALL=en_US.utf-8 LANG=en_US.utf-8

WORKDIR $WDIR

RUN yum -y update && \
    yum install -y python-pip gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make git && \
    yum clean all && rm -rf /var/cache/yum && \
    wget https://www.python.org/ftp/python/${PY_VERSION}/Python-${PY_VERSION}.tgz && \
    tar -xvf Python-${PY_VERSION}.tgz && \
    cd Python-${PY_VERSION} && \
    ./configure --enable-optimizations && \
    make altinstall && \
# Get python major version i.e.: 3.9 from 3.9.13
    export PY_MAJOR=$(echo ${PY_VERSION%.*}) && \
    rm -f /usr/bin/python3 && ln -s /usr/local/bin/python${PY_MAJOR} /usr/bin/python3 && \
    rm -f /usr/bin/pip3 && ln -s /usr/local/bin/pip${PY_MAJOR} /usr/bin/pip3 && \
    python3 -m pip install --upgrade pip && \
    cd $WDIR && \
    rm -rf Python-${PY_VERSION}.tgz Python-${PY_VERSION} && \
    unset PY_MAJOR && \
    cd $WDIR && \
    pip install --no-cache-dir click pandas schema && \
    git clone https://github.com/dmwm/CMSSpark.git && \
    git clone https://github.com/dmwm/CMSMonitoring.git && cd CMSMonitoring && git checkout tags/$CMSMONITORING_TAG -b build && cd ..

WORKDIR ${WDIR}
