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
ARG CMS_TAG

# Install what's needed out of dmwm/rucio/CMS branch
ADD install_mail_templates.sh /tmp/
RUN /tmp/install_mail_templates.sh

# Install globus SDK
RUN python3 -m pip install --no-cache-dir globus-sdk pyyaml
ADD globus-config.yml.j2 /tmp

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py /usr/local/lib/python3.6/site-packages/cmstfc.py
RUN chmod 755 /usr/local/lib/python3.6/site-packages/cmstfc.py

# Delete checks that it exists
ADD https://raw.githubusercontent.com/ericvaandering/rucio/$CMS_TAG/lib/rucio/rse/protocols/gfal.py /usr/local/lib/python3.6/site-packages/rucio/rse/protocols/gfal.py
RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/rse/protocols

ADD cms-entrypoint.sh /

# Eric patches for Globus (need to revisit in 1.26)
# ADD https://raw.githubusercontent.com/ericvaandering/rucio/$CMS_TAG/lib/rucio/transfertool/globusLibrary.py /usr/local/lib/python3.6/site-packages/rucio/transfertool/globusLibrary.py
# RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/transfertool
# ADD https://raw.githubusercontent.com/ericvaandering/rucio/$CMS_TAG/lib/rucio/core/transfer.py /usr/local/lib/python3.6/site-packages/rucio/core/transfer.py
# RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/core
# ADD https://raw.githubusercontent.com/ericvaandering/rucio/$CMS_TAG/lib/rucio/daemons/conveyor/submitter.py /usr/local/lib/python3.6/site-packages/rucio/daemons/conveyor/submitter.py
# ADD https://raw.githubusercontent.com/ericvaandering/rucio/$CMS_TAG/lib/rucio/daemons/conveyor/common.py /usr/local/lib/python3.6/site-packages/rucio/daemons/conveyor/common.py
# RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/daemons/conveyor

# Eric patch for cache-consumer

ADD https://raw.githubusercontent.com/ericvaandering/rucio/fix_cache_consumer/lib/rucio/daemons/cache/consumer.py /usr/local/lib/python3.6/site-packages/rucio/daemons/cache/consumer.py
RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/daemons/cache
ADD https://raw.githubusercontent.com/ericvaandering/rucio/fix_cache_consumer/lib/rucio/core/volatile_replica.py /usr/local/lib/python3.6/site-packages/rucio/core/volatile_replica.py
RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/core
ADD https://raw.githubusercontent.com/ericvaandering/rucio/fix_cache_consumer/lib/rucio/common/stomp_utils.py /usr/local/lib/python3.6/site-packages/rucio/common/stomp_utils.py
RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/common

# Eric patch for kronos

ADD https://raw.githubusercontent.com/ericvaandering/rucio/kronos_both_threads/lib/rucio/daemons/tracer/kronos.py /usr/local/lib/python3.6/site-packages/rucio/daemons/tracer/kronos.py
RUN python3 -m compileall /usr/local/lib/python3.6/site-packages/rucio/daemons/tracer



ADD https://raw.githubusercontent.com/ericvaandering/containers/add_preparer/daemons/rucio.cfg.j2 /tmp/rucio.cfg.j2

ENTRYPOINT ["/cms-entrypoint.sh"]
