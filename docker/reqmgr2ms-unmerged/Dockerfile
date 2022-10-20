FROM registry.cern.ch/cmsweb/reqmgr2ms:HG2211a
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_reqmgr2ms
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# Install and enable the CERN DMC EL7 repository to get up-to-date gfal2 packages
ADD https://dmc-repo.web.cern.ch/dmc-repo/dmc-el7.repo /etc/yum.repos.d/dmc-el7.repo
# Install the gfal2 base libraries (from the production DMC repo)
# Also install the external plugins required for full gfal2 functionality
RUN sudo yum install -y gfal2 gfal2-devel \
    gfal2-plugin-file \
    gfal2-plugin-gridftp \
    gfal2-plugin-http \
    gfal2-plugin-srm \
    gfal2-plugin-xrootd \
    xrootd-client \
    && sudo yum clean all && sudo rm -rf /var/cache/yum

# switch to user
ARG CMSK8S
ENV CMSK8S=$CMSK8S

# install
#RUN $WDIR/install.sh

# run the service
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
USER $USER
WORKDIR $WDIR
#CMD ["./run.sh"]
