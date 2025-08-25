FROM registry.cern.ch/cmsweb/exporters:20250519-stable as exporters
FROM python:3.12-trixie
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

# see https://docs.docker.com/build/building/best-practices/#apt-get
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl libcurl4 libcurl4-openssl-dev \ 
    apache2-utils \
    sudo less vim git patch \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python
RUN mkdir /etc/grid-security
COPY --from=exporters /data/cmsweb-ping /usr/bin/cmsweb-ping
COPY --from=exporters /data/process_exporter /usr/bin/process_exporter
COPY --from=exporters /data/cpy_exporter /usr/bin/cpy_exporter
ADD run.sh /data/run.sh
ADD monitor.sh /data/monitor.sh
ADD manage /data/manage
WORKDIR /data
