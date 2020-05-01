# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2019-2020

ARG RUCIO_VERSION

FROM rucio/probes:latest 

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py  /usr/lib/python2.7/site-packages/cmstfc.py
RUN chmod 755 /usr/lib/python2.7/site-packages/cmstfc.py

# TODO: move to sqlalchemy and feed upstream
ADD https://raw.githubusercontent.com/ericvaandering/probes/more_cms_probes/common/check_updated_dids /probes/common
ADD https://raw.githubusercontent.com/ericvaandering/probes/more_cms_probes/common/check_new_dids /probes/common
ADD https://raw.githubusercontent.com/ericvaandering/probes/more_cms_probes/common/check_expired_dids /probes/common
RUN chmod +x /probes/common/check_*

# Was in upstream, aside from the connection counting, probably not needed anymore.
# TODO: should move that one into our own repository area and create a way to run user specified probes

# CMS Specific stuff for problems with the central REPO
# ADD https://raw.githubusercontent.com/ericvaandering/rucio/2fd5c60597ecb852487bde7d960a35230b2acd98/lib/rucio/common/schema/cms.py   /usr/lib/python2.7/site-packages/rucio/common/schema/cms.py
# RUN rm /usr/lib/python2.7/site-packages/rucio/common/schema/cms.pyc
# RUN (cd /usr/lib/python2.7/site-packages/rucio/common/schema/; python -m compileall .; ls -l)

# WORKDIR /probes
# RUN git remote add ewv https://github.com/ericvaandering/probes.git
# RUN git fetch ewv
# RUN git checkout count_connections
# WORKDIR /
