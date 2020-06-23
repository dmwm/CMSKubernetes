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

# Install what's needed out of dmwm/rucio/CMS branch
RUN yum install -y git
WORKDIR /opt/rucio/etc/mail_templates/
WORKDIR /root
RUN git clone https://github.com/dmwm/rucio.git
WORKDIR /root/rucio
RUN git checkout CMS
RUN cp etc/mail_templates/* /opt/rucio/etc/mail_templates/

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py /usr/lib/python2.7/site-packages/cmstfc.py
RUN chmod 755 /usr/lib/python2.7/site-packages/cmstfc.py

ADD cms-entrypoint.sh /

# Better delete

ADD https://raw.githubusercontent.com/ericvaandering/rucio/cms_nano3/lib/rucio/rse/protocols/gfal.py /usr/lib/python2.7/site-packages/rucio/rse/protocols/gfal.py
RUN python -m compileall /usr/lib/python2.7/site-packages/rucio/rse/protocols

# Our schema
ADD https://raw.githubusercontent.com/ericvaandering/rucio/cms_nano3/lib/rucio/common/schema/cms.py /usr/lib/python2.7/site-packages/rucio/common/schema/cms.py
RUN python -m compileall /usr/lib/python2.7/site-packages/rucio/common/schema
ADD https://raw.githubusercontent.com/ericvaandering/rucio/cms_nano3/lib/rucio/api/did.py /usr/lib/python2.7/site-packages/rucio/api/did.py
ADD https://raw.githubusercontent.com/ericvaandering/rucio/cms_nano3/lib/rucio/api/replica.py /usr/lib/python2.7/site-packages/rucio/api/replica.py
RUN python -m compileall /usr/lib/python2.7/site-packages/rucio/api

ENTRYPOINT ["/cms-entrypoint.sh"]

