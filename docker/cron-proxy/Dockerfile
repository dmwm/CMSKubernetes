# Start from a minimal EL9 base image
FROM gitlab-registry.cern.ch/linuxsupport/alma9-base:latest 

# Set metadata for the image
LABEL maintainer="carlos.borrajo.gomez@cern.ch"
LABEL description="Minimal AL9-based cron proxy image"

# Set environment variables
ENV WDIR=/data
ARG stage=stable

# Create working directory
RUN mkdir -p ${WDIR}

# YUM repos needed
RUN touch /etc/yum.repos.d/config9al-$(echo $stage).repo && \
    echo -e "[config9al-$(echo $stage)]\n\
name=Utilities for Configuration [$(echo $stage)]\n\
baseurl=http://linuxsoft.cern.ch/internal/repos/config9al-$(echo $stage)/x86_64/os\n\
enabled=1\n\
gpgcheck=True\n\
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-kojiv2\n\
priority=30" > /etc/yum.repos.d/config9al-$(echo $stage).repo

# Define EPEL repository
RUN touch /etc/yum.repos.d/epel.repo && \
    echo -e "[epel]\n\
name=Extra Packages for Enterprise Linux 9 [HEAD]\n\
baseurl=http://linuxsoft.cern.ch/epel/9/Everything/x86_64\n\
enabled=1\n\
gpgcheck=1\n\
gpgkey=http://linuxsoft.cern.ch/epel/RPM-GPG-KEY-EPEL-9\n\
exclude=collectd*,libcollectd*,mcollective,perl-Authen-Krb5,perl-Collectd,puppet,python*collectd_systemd*,koji*,python*koji*\n\
priority=20" > /etc/yum.repos.d/epel.repo

ADD http://linuxsoft.cern.ch/wlcg/wlcg-el9.repo /etc/yum.repos.d/wlcg.repo
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/egi-trustanchors.repo /etc/yum.repos.d/egi.repo
ADD http://linuxsoft.cern.ch/wlcg/RPM-GPG-KEY-wlcg /etc/pki/rpm-gpg/RPM-GPG-KEY-wlcg

# Install necessary dependencies for the proxy script
RUN yum install -y \
    python-dateutil \
    fetch-crl \
    myproxy \
    voms \
    voms-clients-cpp \
    && yum clean all

RUN dnf install -y \
    bash \
    curl \
    sudo \
    wlcg-voms-cms \
    wlcg-iam-lsc-cms-3.0.0 \
    wlcg-iam-vomses-cms \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Install kubectl CLI
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
mv kubectl /usr/bin && chmod +x /usr/bin/kubectl

# Run the service
ADD proxy.sh $WDIR/proxy.sh

WORKDIR $WDIR
CMD ["./proxy.sh"]

