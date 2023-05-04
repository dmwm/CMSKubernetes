FROM cern/cc7-base:20230426-1
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo /etc/yum.repos.d/egi.repo
ADD http://linuxsoft.cern.ch/wlcg/wlcg-centos7.repo /etc/yum.repos.d/wlcg-centos7.repo
ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
# always run yum install and yum clean and remove cache in one command
# see https://developers.redhat.com/blog/2016/03/09/more-about-docker-images-size/
RUN yum install -y sudo cern-get-certificate fetch-crl \
    CERN-CA-certs ca-certificates dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
    ca_EG-GRID ca_CERN-GridCA ca_CERN-LCG-IOTA-CA ca_CERN-Root-2 \
    && yum clean all && rm -rf /var/cache/yum && ln -s /bin/bash /usr/bin/bashs && echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360" > /etc/cron.d/fetch-crl-docker

RUN yum install -y --nogpgcheck wlcg-voms-cms

RUN yum info CERN-CA-certs
RUN update-ca-trust
