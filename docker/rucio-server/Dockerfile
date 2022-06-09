# Copyright European Organization for Nuclear Research (CERN) 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Authors:
# - Eric Vaandering, <ewv@fnal.gov>, 2018

ARG RUCIO_VERSION

FROM rucio/rucio-server:release-$RUCIO_VERSION

ARG CMS_TAG

ADD https://raw.githubusercontent.com/dmwm/CMSRucio/master/docker/CMSRucioClient/scripts/cmstfc.py  /usr/local/lib/python3.6/site-packages/cmstfc.py

RUN chmod 755 /usr/local/lib/python3.6/site-packages/cmstfc.py

RUN yum -y install http://linuxsoft.cern.ch/wlcg/centos7/x86_64/wlcg-repo-1.0.0-1.el7.noarch.rpm && \
    yum clean all && \
    rm -rf /var/cache/yum
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo /etc/yum.repos.d/egi.repo
RUN yum update  -y && \
    yum clean all && \
    rm -rf /var/cache/yum

# We need to install all the certificates and set up the revocation list.
# This is necessary for Go to be able to access the auth server with X509

RUN yum -y install ca-policy-egi-core ca-certificates.noarch fetch-crl cronie psmisc && \
    yum clean all && \
    rm -rf /var/cache/yum
ENV RUCIO_CA_PATH="/etc/grid-security/certificates"
ADD cms-entrypoint.sh /
RUN echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360 ; killall -HUP httpd" > /etc/cron.d/fetch-crl-docker

# Install what's needed out of dmwm/rucio/CMS branch
ADD install_mail_templates.sh /tmp/
RUN /tmp/install_mail_templates.sh

# Might get recreated if apache was upgraded
RUN rm -f /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/userdir.conf /etc/httpd/conf.d/ssl.conf

ENTRYPOINT ["/cms-entrypoint.sh"]
