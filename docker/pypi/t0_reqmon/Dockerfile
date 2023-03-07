FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230306
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ENV TAG=X.Y.Z
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
