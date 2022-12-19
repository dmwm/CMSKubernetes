FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20221219
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN pip install reqmgr2ms-output
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
#ADD deploy-centralvenv.sh /data/deploy-centralvenv.sh
#RUN apt-get install -y git tree python3-venv
#RUN /data/deploy-centralvenv.sh -l reqmgr2ms-output==2.1.4rc3 -d /data/tmp/WMCore.venv333/ -y
CMD ["python3"]
