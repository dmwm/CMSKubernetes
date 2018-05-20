FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=sw
ADD install.sh $WDIR/install.sh

RUN yum update -y && yum clean all

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# install
RUN $WDIR/install.sh

# run the service
ADD run.sh $WDIR/run.sh
USER $USER
WORKDIR $WDIR
CMD ["./run.sh"]
