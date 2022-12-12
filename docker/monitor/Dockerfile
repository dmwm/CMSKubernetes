FROM cmssw/cmsweb:20221130-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_monitor

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# pass env variable to the build
ARG CMSK8S
ENV CMSK8S=$CMSK8S

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# run the service
ADD monitor.sh $WDIR/monitor.sh

USER $USER
WORKDIR $WDIR
CMD ["./monitor.sh"]
