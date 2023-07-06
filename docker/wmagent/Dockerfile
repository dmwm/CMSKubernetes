FROM registry.cern.ch/cmsweb/cmsweb:20221130-stable

RUN echo "Adding the AFS cmst1:zh user"
RUN groupadd -g 1399 zh
RUN adduser -u 31961 -g 1399 cmst1

### Setup directory and files permissions
RUN install -o cmst1 -g 1399 -d /data/srv /data/admin /data/certs
RUN chown root:1399 /data

ARG WMA_TAG=None
ENV WDIR=/data

# Add install script
ADD install.sh ${WDIR}/install.sh

# Add wmagent run script
ADD run.sh ${WDIR}/run.sh

RUN chown cmst1 ${WDIR}/run.sh ${WDIR}/install.sh

USER cmst1

WORKDIR ${WDIR}

RUN ${WDIR}/install.sh ${WMA_TAG}

RUN echo "Installation completed!"

# commenting this out for testing
#ENTRYPOINT ["./run.sh"]
ENTRYPOINT ["/bin/bash", "-l"]
