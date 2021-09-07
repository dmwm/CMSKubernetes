FROM cmssw/reqmgr2ms:HG2109b
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ENV USER=_reqmgr2ms
USER ${USER}

# start the setup
RUN mkdir -p $WDIR
WORKDIR ${WDIR}

# Install gfal2-python3 dependecies
RUN sudo yum install -y \
    gfal2-python3 \
    gfal2-plugin-file \
    gfal2-plugin-gridftp \
    gfal2-plugin-http \
    gfal2-plugin-srm \
    gfal2-plugin-xrootd \
    xrootd-client \
    && sudo yum clean all && \
    sudo rm -rf /var/cache/yum

ENV PYTHONPATH="$PYTHONPATH:/usr/lib64/python3.6/site-packages/"
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
