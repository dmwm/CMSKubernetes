FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20221213
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV TAG=2.1.4
RUN pip install reqmgr2ms-rulecleaner==$TAG
RUN sed -i -e "s,-config.py,-config-ruleCleaner.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-ruleCleaner.py,g" /data/manage
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
