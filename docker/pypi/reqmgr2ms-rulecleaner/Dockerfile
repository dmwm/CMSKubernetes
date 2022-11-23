FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20221123
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV TAG=2.1.4
RUN pip install reqmgr2ms-rulecleaner==$TAG
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
ADD run.sh /data/run.sh
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
