FROM cmssw/cmsweb
# FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_proxy

RUN yum update -y && yum clean all

# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR}
# add user to sudoers file
RUN echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install latest kubectl
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN mv kubectl /usr/bin
RUN chmod +x /usr/bin/kubectl

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# run the service
ADD proxy.sh $WDIR/proxy.sh

USER $USER
WORKDIR $WDIR
CMD ["./proxy.sh"]
