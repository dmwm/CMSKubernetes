FROM registry.cern.ch/cmsweb/cmsweb-base as cmsweb-base
FROM registry.cern.ch/cmsweb/exporters as exporters
FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update && \
    apt-get install -y curl vim libcurl4 libcurl4-openssl-dev python3-pycurl pip sudo less && \
    apt-get clean
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN mkdir /etc/grid-security
COPY --from=cmsweb-base /etc/grid-security/certificates /etc/grid-security/certificates
COPY --from=cmsweb-base /etc/grid-security/vomsdir /etc/grid-security/vomsdir
COPY --from=exporters /data/cmsweb-ping /usr/bin/cmsweb-ping
COPY --from=exporters /data/process_exporter /usr/bin/process_exporter
COPY --from=exporters /data/cpy_exporter /usr/bin/cpy_exporter
ADD run.sh /data/run.sh
ADD monitor.sh /data/monitor.sh
ADD manage /data/manage
WORKDIR /data
