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
    nano openssh-client \
    && yum clean all \
    && rm -rf /var/cache/yum


ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py  /usr/lib/python2.7/site-packages/cmstfc.py
RUN chmod 755 /usr/lib/python2.7/site-packages/cmstfc.py

ADD upgrade_image_start.sh /tmp
RUN chmod 755 /tmp/upgrade_image_start.sh

ADD alembic.ini.j2 /tmp

ENTRYPOINT ["/tmp/upgrade_image_start.sh"]

