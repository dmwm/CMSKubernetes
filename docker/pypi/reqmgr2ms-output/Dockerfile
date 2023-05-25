FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230525
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV TAG=X.Y.Z
RUN pip install reqmgr2ms-output==$TAG
RUN sed -i -e "s,-config.py,-config-output.py,g" /data/run.sh
RUN sed -i -e "s,config.py,config-output.py,g" /data/manage
ENV WDIR=/data
ENV USER=_reqmgr2ms
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
