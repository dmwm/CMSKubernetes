FROM cern/cc7-base:20220601-1
MAINTAINER Ceyhun Uzunoglu ceyhunuzngl@gmail.com

ENV WDIR=/data
WORKDIR $WDIR

# Should be full such that includes minor version
ARG PY_VERSION=3.9.13

RUN yum -y update && \
    yum install -y python-pip gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make && \
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
    unset PY_MAJOR

# start the setup
WORKDIR ${WDIR}
