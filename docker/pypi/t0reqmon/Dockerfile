FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250716-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
# TAG to be passed at build time through `--build-arg TAG=<PYPI_TAG>`. Default: None
ARG TAG=None
RUN pip install reqmon==$TAG
ENV WDIR=/data
ENV USER=_t0_reqmon
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USER}
RUN sudo chown -R $USER.$USER $WDIR
WORKDIR $WDIR
RUN sed -i -e "s,srv=.*,srv=t0_reqmon,g" run.sh
CMD ["python3"]
