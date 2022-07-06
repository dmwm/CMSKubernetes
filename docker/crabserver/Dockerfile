FROM registry.cern.ch/cmsweb/cmsweb:20220601-stable
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_crabserver
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

COPY addGH.sh monitor.sh run.sh start.sh stop.sh $WDIR/
RUN ./addGH.sh

# run the service
USER $USER
WORKDIR $WDIR
#CMD ["./run.sh"]
