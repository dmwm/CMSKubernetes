# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2018


FROM rucio/rucio-server:release-1.19.6

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py  /usr/lib/python2.7/site-packages/cmstfc.py

RUN chmod 755 /usr/lib/python2.7/site-packages/cmstfc.py

RUN yum -y install http://linuxsoft.cern.ch/wlcg/centos7/x86_64/wlcg-repo-1.0.0-1.el7.noarch.rpm
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo /etc/yum.repos.d/egi.repo
RUN yum update  -y
RUN yum -y install ca-policy-egi-core
RUN yum -y install ca-certificates.noarch fetch-crl cronie

ADD cms-entrypoint.sh /

RUN echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360 " > /etc/cron.d/fetch-crl-docker


ENTRYPOINT ["/cms-entrypoint.sh"]
