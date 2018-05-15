FROM cmssw/cmsweb
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=sw
ADD install.sh $WDIR/install.sh
ADD run.sh $WDIR/run.sh
ADD proxy.sh $WDIR/proxy.sh

RUN yum update -y && yum clean all

# create bashs link to bash
# RUN ln -s /bin/bash /usr/bin/bashs
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# add fake host certs since we'll manage them at run time
RUN mkdir -p /data/certs
RUN echo "bla" > /data/certs/hostcert.pem
RUN echo "bla" > /data/certs/hostkey.pem
RUN chmod 0600 /data/certs/hostkey.pem

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# install
RUN $WDIR/install.sh

# run the service
WORKDIR $WDIR
CMD ["./run.sh"]
