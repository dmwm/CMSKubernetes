FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230123
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV TAG=X.Y.Z
RUN pip install reqmon==$TAG
ENV WDIR=/data
ENV USER=_reqmon
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
