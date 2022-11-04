FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl libcurl4 libcurl4-openssl-dev python3-pycurl pip apache2-utils sudo
RUN ln -s /usr/bin/python3 /usr/bin/python
ENV TAG=2.1.4rc3
RUN pip install reqmgr2ms-rulecleaner==$TAG
RUN mkdir /etc/grid-security
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
ADD run.sh /data/run.sh
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
