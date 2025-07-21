FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250716-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=2.1.1
RUN pip install git+https://github.com/dmwm/t0wmadatasvc.git@$TAG
ENV WDIR=/data
ENV USER=_t0wmadatasvc
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
CMD ["python3"]
