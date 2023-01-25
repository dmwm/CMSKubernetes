FROM registry.cern.ch/cmsweb/cmsweb-base as cmsweb-base
FROM registry.cern.ch/cmsweb/exporters as exporters
FROM python:3.8-bullseye
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN apt-get update
RUN apt-get install -y curl vim libcurl4 libcurl4-openssl-dev python3-pycurl pip apache2-utils sudo less
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN mkdir /etc/grid-security
COPY --from=cmsweb-base /etc/grid-security/certificates /etc/grid-security/certificates
COPY --from=exporters /data/cmsweb-ping /usr/bin/cmsweb-ping
COPY --from=exporters /data/process_exporter /usr/bin/process_exporter
COPY --from=exporters /data/cpy_exporter /usr/bin/cpy_exporter
RUN pip install dbs3-client
ADD run.sh /data/run.sh
ADD monitor.sh /data/monitor.sh
ADD manage /data/manage
WORKDIR /data
