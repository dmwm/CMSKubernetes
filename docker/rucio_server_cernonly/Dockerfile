# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Cedric Serfon, <cedric.serfon@cern.ch>, 2017
# Modified by Igor Mandrichenko, January 2018

# Not on docker hub yet 

FROM rucio_server_cms

ADD RPM-GPG-KEY-cern /etc/pki/rpm-gpg/RPM-GPG-KEY-cern
ADD cernonly.repo /etc/yum.repos.d/cernonly.repo

## Need to remove conflicting package:
RUN yum -y erase oracle-instantclient12.2-basiclite && \
    yum -y install oracle-instantclient-sqlplus && \
    yum -y install oracle-instantclient-tnsnames.ora && \
    yum clean all && \
    rm -rf /var/cache/yum

