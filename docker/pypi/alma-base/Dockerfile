FROM registry.cern.ch/cmsweb/cmsweb-base as cmsweb-base
FROM registry.cern.ch/cmsweb/exporters as exporters
FROM almalinux:latest
MAINTAINER Alan Malta alan.malta@cern.ch

# base image stuff: certificates, monitoring, exporters, etc
RUN mkdir /etc/grid-security
COPY --from=cmsweb-base /etc/grid-security/certificates /etc/grid-security/certificates
COPY --from=cmsweb-base /etc/grid-security/vomsdir /etc/grid-security/vomsdir
COPY --from=cmsweb-base /etc/vomses /etc/vomses
COPY --from=exporters /data/cmsweb-ping /usr/bin/cmsweb-ping
COPY --from=exporters /data/process_exporter /usr/bin/process_exporter
COPY --from=exporters /data/cpy_exporter /usr/bin/cpy_exporter

# Required OS packages
RUN dnf -y upgrade && \
    dnf -y install --skip-broken curl libcurl && \
    dnf -y install sudo vim less procps python3-pycurl pip && \
    dnf clean all
RUN ln -s /usr/bin/python3 /usr/bin/python

ENV WDIR=/data
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
ADD manage $WDIR/manage
WORKDIR /data