FROM registry.cern.ch/cmsweb/dmwm-base:alma9-py3.12-20250529
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

RUN yum install -y git
ENV WDIR=/data
ENV USER=_t0wmadatasvc
ADD install.sh $WDIR/install.sh

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# pass env variable to the build
ARG CMSK8S
ENV CMSK8S=$CMSK8S

# install
RUN $WDIR/install.sh

# run the service
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh

USER $USER
WORKDIR $WDIR
CMD ["./run.sh"]

