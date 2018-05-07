FROM cern/cc7-base
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ADD egi-trustanchors.repo /etc/yum.repos.d/egi-trustanchors.repo
ADD wlcg.slc6.repo /etc/yum.repos.d/wlcg.slc6.repo
ADD epel.repo /etc/yum.repos.d/epel.repo
ADD RPM-GPG-KEY-wlcg /etc/pki/rpm-gpg/RPM-GPG-KEY-wlcg

RUN yum update -y && yum clean all
RUN yum install -y cern-get-certificate fetch-crl
RUN yum install -y git-core zip unzip which file bzip2 e2fsprogs e2fsprogs-libs compat-libstdc++-33 \
    CERN-CA-certs ca-certificates dummy-ca-certs  ca_CERN-GridCA ca_CERN-LCG-IOTA-CA ca_CERN-Root-2 \
    wlcg-voms-cms krb5-workstation krb5-libs pam_krb5 myproxy voms-clients-cpp voms-clients-java \
    sudo openssl openssl-libs openssh openssh-clients python-backports-ssl_match_hostname \
    globus-gsi-openssl-error globus-gsi-proxy-ssl globus-openssl-module \
    perl-Thread-Queue zsh tk freetype perl-ExtUtils-Embed fontconfig \
    perl-Test-Harness perl-Data-Dumper perl-Digest-MD5 perl-Switch perl-Env \
    libX11-devel libX11 libXmu libSM libICE libXcursor libXext libXrandr libXft \
    mesa-libGLU mesa-libGL libXi libXinerama libXft-devel libXrender libXpm \
    libXpm-devel libXext-devel mesa-libGLU-devel
RUN yum clean all

# create bashs link to bash
RUN ln -s /bin/bash /usr/bin/bashs

# cd to workdir
WORKDIR $WDIR

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz
RUN tar xfz go1.10.1.linux-amd64.tar.gz
RUN mkdir -p $WDIR/gopath
RUN rm go1.10.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# start the setup
WORKDIR ${WDIR}
