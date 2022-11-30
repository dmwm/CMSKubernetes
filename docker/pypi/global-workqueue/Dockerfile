FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20221129
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV TAG=2.1.4
RUN pip install global-workqueue==$TAG
ENV WDIR=/data
ENV USER=_workqueue
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
