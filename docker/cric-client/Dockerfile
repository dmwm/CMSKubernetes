FROM cern/cc7-base:20181210
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_cric

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
ADD cric.sh $WDIR/cric.sh

USER $USER
WORKDIR $WDIR
CMD ["./cric.sh"]
