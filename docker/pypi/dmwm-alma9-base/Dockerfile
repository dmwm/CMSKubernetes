FROM registry.cern.ch/cmsweb/cmsweb-alma9-base:20250515 AS cmsweb-base
FROM registry.cern.ch/cmsweb/exporters AS exporters
FROM almalinux:latest
LABEL org.opencontainers.image.authors="Alan Malta alan.malta@cern.ch"

# base image stuff: certificates, monitoring, exporters, etc
RUN mkdir /etc/grid-security
COPY --from=cmsweb-base /etc/grid-security/certificates /etc/grid-security/certificates
COPY --from=cmsweb-base /etc/grid-security/vomsdir /etc/grid-security/vomsdir
COPY --from=exporters /data/cmsweb-ping /usr/bin/cmsweb-ping
COPY --from=exporters /data/process_exporter /usr/bin/process_exporter
COPY --from=exporters /data/cpy_exporter /usr/bin/cpy_exporter

# Required OS packages
RUN dnf -y upgrade && \
    dnf -y install --skip-broken curl libcurl && \
    dnf -y install sudo vim less procps && \
    dnf -y install python3.12 python3.12-pip python3-pycurl pip && \
    dnf clean all
RUN ln -s /usr/bin/python3.12 /usr/bin/python

ENV WDIR=/data
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
ADD manage $WDIR/manage
WORKDIR /data