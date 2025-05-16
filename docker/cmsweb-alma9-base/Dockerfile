FROM cern/alma9-base:latest
LABEL author="Dennis Lee dylee@fnal.gov"

# Install EPEL repository (required for voms, fetch-crl and CA-related packages)
RUN dnf -y install epel-release && dnf -y upgrade && \
    dnf install -y http://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm && \
    dnf clean all

ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/egi-trustanchors.repo /etc/yum.repos.d/egi.repo

# Upgrade packages  from the base image and install CMSWEB required packages
RUN dnf -y install fetch-crl cronie cern-get-certificate CERN-CA-certs ca-certificates \
    dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
    ca_CERN-GridCA ca_CERN-Root-2 \
    wlcg-voms-cms && \
    dnf clean all && \
    echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360" > /etc/cron.d/fetch-crl-docker

# Required OS packages
RUN dnf -y install vim less procps python3-pycurl pip && dnf clean all
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN update-ca-trust
