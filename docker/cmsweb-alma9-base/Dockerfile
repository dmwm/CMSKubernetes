FROM cern/alma9-base:latest

# Install EPEL repository (required for voms, fetch-crl and CA-related packages)
RUN dnf -y install epel-release && dnf -y upgrade && dnf clean all

# Upgrade packages from the base image and install CMSWEB required packages
RUN dnf -y install fetch-crl cern-get-certificate CERN-CA-certs ca-certificates && dnf clean all

# Required OS packages
RUN dnf -y install vim less procps python3-pycurl pip && dnf clean all
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN update-ca-trust
