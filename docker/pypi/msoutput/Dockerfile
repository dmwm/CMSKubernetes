FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20240923-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=None
RUN pip install msoutput==$TAG
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
