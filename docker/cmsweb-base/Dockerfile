FROM cern/cc7-base:20200531-2.x86_64
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo /etc/yum.repos.d/egi.repo
ADD http://linuxsoft.cern.ch/wlcg/wlcg-centos7.repo /etc/yum.repos.d/wlcg-centos7.repo
ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
RUN yum install -y sudo cern-get-certificate fetch-crl \
    CERN-CA-certs ca-certificates dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
    ca_EG-GRID ca_CERN-GridCA ca_CERN-LCG-IOTA-CA ca_CERN-Root-2
RUN ln -s /bin/bash /usr/bin/bashs

