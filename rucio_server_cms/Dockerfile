# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Cedric Serfon, <cedric.serfon@cern.ch>, 2017
# Modified by Igor Mandrichenko, January 2018

FROM ericvaandering/rucio_server

EXPOSE 443
EXPOSE 8443
EXPOSE 80
EXPOSE 8080
EXPOSE 8088

# Get all the repositories setup

ADD https://raw.githubusercontent.com/rucio/rucio/master/etc/docker/dev/ca.repo /etc/yum.repos.d/ca.repo
ADD http://linuxsoft.cern.ch/wlcg/centos7/x86_64/wlcg-repo-1.0.0-1.el7.noarch.rpm /tmp/

RUN yum install -y epel-release.noarch && yum clean all && rm -rf /var/cache/yum
RUN yum -y install /tmp/wlcg-repo-1.0.0-1.el7.noarch.rpm &&  yum clean all &&  rm -rf /var/cache/yum && rm /tmp/wlcg-repo-1.0.0-1.el7.noarch.rpm

# Get all the certificate stuff for CERN setup

RUN yum -y install ca-certificates.noarch lcg-CA voms-clients-cpp wlcg-voms-cms && \
    yum clean all && \
    rm -rf /var/cache/yum

ENV container docker

# Add various rucio config files to the image

ADD etc/httpd/conf.d/rucio.conf /etc/httpd/conf.d/
ADD etc/httpd/conf/httpd.conf /etc/httpd/conf/
ADD etc/supervisord.d/rucio.ini /etc/supervisord.d/
ADD opt/rucio/etc/* /opt/rucio/etc/
ADD opt/rucio/etc/web/aliases-py27.conf /opt/rucio/etc/web/

RUN cp /etc/grid-security/certificates/CERN-GridCA.pem /opt/rucio/etc/web/ca.pem

# Not sure why we need OpenSSL from a tarball

ADD OpenSSL.tar /usr/lib64/python2.7/site-packages/

# Setup cron and start services

ADD opt/rucio/tools/* /opt/rucio/tools/
RUN crontab /opt/rucio/tools/delegate_fts_proxy.cron

RUN systemctl enable httpd.service
RUN systemctl enable supervisord.service

