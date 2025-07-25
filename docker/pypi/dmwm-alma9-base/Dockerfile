FROM registry.cern.ch/cmsweb/exporters AS exporters
FROM cern/alma9-base:latest
LABEL org.opencontainers.image.authors="Alan Malta alan.malta@cern.ch, Dennis Lee dylee@fnal.gov"

# Required OS packages
RUN dnf -y upgrade && \
    dnf -y install --skip-broken curl libcurl && \
    dnf -y install sudo vim less procps && \
    dnf -y install python3-pycurl pip && \
    dnf clean all
RUN ln -s /usr/bin/python3.9 /usr/bin/python

# base image stuff: monitoring, exporters, etc
COPY --from=exporters /data/cmsweb-ping /usr/bin/cmsweb-ping
COPY --from=exporters /data/process_exporter /usr/bin/process_exporter
COPY --from=exporters /data/cpy_exporter /usr/bin/cpy_exporter

ENV WDIR=/data
ADD run.sh $WDIR/run.sh
ADD monitor.sh $WDIR/monitor.sh
ADD manage $WDIR/manage
WORKDIR /data
