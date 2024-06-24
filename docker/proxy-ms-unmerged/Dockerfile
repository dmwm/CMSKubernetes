FROM registry.cern.ch/cmsweb/cmsweb:20240501-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_proxy

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
ADD proxy.sh $WDIR/proxy.sh

USER $USER
WORKDIR $WDIR
CMD ["./proxy.sh"]
