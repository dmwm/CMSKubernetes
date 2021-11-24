FROM registry.cern.ch/cmsweb/cmsweb-base:20211103-stable as web-builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_cmsweb

# create bashs link to bash
#RUN ln -s /bin/bash /usr/bin/bashs
# add new user
RUN useradd ${USER} && install -o ${USER} -d ${WDIR} && echo "%$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# switch to user
USER ${USER}

# add fake host certs since we'll manage them at run time

WORKDIR ${WDIR}
ADD run.sh $WDIR

# install

RUN sudo yum install -y git jq python3-devel python3-pip && sudo yum update -y && sudo yum clean all && sudo rm -rf /var/cache/yum && sudo pip3 install --upgrade pip && sudo pip3 install --upgrade setuptools && sudo pip3 install python-openstackclient && sudo pip3 install python-manilaclient 

RUN git clone https://github.com/dmwm/CMSKubernetes.git

CMD ["./run.sh"]
