FROM cmssw/cmsweb
# FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=dbs

ADD install.sh $WDIR/install.sh
ADD run.sh $WDIR/run.sh

RUN yum update -y && yum clean all

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}
# add fake host certs since we'll pass them via docker at run time
RUN mkdir -p /data/certs
RUN touch /data/certs/hostcert.pem
RUN touch /data/certs/hostkey.pem
RUN chmod 0600 /data/certs/hostkey.pem

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# install
RUN $WDIR/install.sh

# run the service
USER $USER
WORKDIR $WDIR
CMD ["./run.sh"]
