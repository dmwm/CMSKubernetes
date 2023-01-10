FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230110
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y libmariadb-dev-compat libmariadb-dev apache2-utils sudo
ENV TAG=2.1.4
RUN pip install wmagent==$TAG
ENV WDIR=/data
ENV USER=_wmagent
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
