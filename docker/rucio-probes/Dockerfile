# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2018

ARG RUCIO_VERSION

FROM rucio/rucio-daemons:release-$RUCIO_VERSION

RUN yum install -y git \
    nano \
    && yum clean all \
    && rm -rf /var/cache/yum

WORKDIR /root

COPY scripts /root/scripts

# Pull some useful stuff out of git

RUN git clone https://github.com/rucio/probes.git

WORKDIR /root/probes/common

ENTRYPOINT ["/bin/bash", "-c", "sleep infinity"]
