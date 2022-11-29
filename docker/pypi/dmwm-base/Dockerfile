FROM registry.cern.ch/cmsweb/cmsweb-base as cmsweb-base
FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl vim libcurl4 libcurl4-openssl-dev python3-pycurl pip apache2-utils sudo less
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN mkdir /etc/grid-security
COPY --from=cmsweb-base /etc/grid-security/certificates /etc/grid-security/certificates
RUN pip install dbs3-client
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
ADD run.sh /data/run.sh
WORKDIR $WDIR
