# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2018

ARG RUCIO_VERSION

FROM cmssw/rucio-daemons:release-$RUCIO_VERSION

RUN yum install -y git \
    nano \
    && yum clean all \
    && rm -rf /var/cache/yum

WORKDIR /root
RUN pip3 --no-cache-dir install pyyaml

COPY scripts /root/scripts

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/phedex.py  /root/scripts
ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/CMSRucio.py  /root/scripts
ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/syncaccounts.py  /root/scripts

ADD cms-entrypoint.sh /
ADD sync-live-check.sh /

ENTRYPOINT ["/cms-entrypoint.sh"]
