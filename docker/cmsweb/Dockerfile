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
    cmake voms voms-devel globus-gsi-credential-devel globus-gsi-cert-utils-devel \
    globus-common-devel globus-gsi-sysconfig globus-gsi-sysconfig-devel globus-gsi-callback-devel \
    globus-gsi-openssl-error globus-gsi-proxy-ssl globus-openssl-module \
    shibboleth log4shib xmltooling-schemas opensaml-schemas \
    perl-Thread-Queue zsh tk freetype perl-ExtUtils-Embed fontconfig \
    perl-Test-Harness perl-Data-Dumper perl-Digest-MD5 perl-Switch perl-Env \
    libX11-devel libX11 libXmu libSM libICE libXcursor libXext libXrandr libXft \
    mesa-libGLU mesa-libGL libXi libXinerama libXft-devel libXrender libXpm \
    libXpm-devel libXext-devel mesa-libGLU-devel \
    libaio libaio-devel net-tools lsof bind-utils initscripts patch
RUN yum install -y voms-devel globus-gsi-credential-devel globus-gsi-cert-utils-devel \
    globus-common-devel globus-gsi-sysconfig-devel globus-gsi-callback-devel
RUN yum install -y ca_DigiCertAssuredIDRootCA-Root ca_DigiCertGridRootCA-Root ca_UKeScienceRoot-2007 \
    ca_QuoVadis-Root-CA2G3 ca_AddTrust-External-CA-Root ca_COMODO-RSA-CA ca_QuoVadis-Root-CA3G3 \
    ca_DarkMatterPrivateRootCAG4 ca_KENETROOTCA ca_CNRS2 ca_CNRS2-Projets ca_CERN-Root-2 \
    ca_CESNET-CA-Root ca_CESNET-CA-3 ca_CERN-GridCA ca_CNRS2-Grid-FR ca_KENETCA-ICA-2015 \
    ca_DarkMatterIGTFCA ca_DarkMatterAssuredCA ca_InCommon-IGTF-Server-CA ca_DarkMatterSecureCA \
    ca_UKeScienceCA-2B ca_DigiCertGridCA-1-Classic ca_DigiCertGridCA-1G2-Classic-2015 \
    ca_TERENAeSciencePersonalCA3 ca_DigiCertGridTrustCAG2-Classic ca_TERENA-eScience-SSL-CA-3 \
    ca_DigiCertGridTrustCA-Classic ca_AustrianGrid ca_NCSA-tfca-2013 ca_IHEP-2013 \
    ca_DFN-GridGermany-Root ca_REUNA-ca ca_NorduGrid-2015 ca_cilogon-osg ca_EG-GRID \
    ca_NERSC-SLCS ca_MD-Grid-CA-T ca_AC-GRID-FR-Robots ca_ANSPGrid ca_IRAN-GRID ca_TSU-GE \
    ca_KISTIv3 ca_QuoVadis-Root-CA2 ca_GridCanada ca_SDG-G2 ca_SRCE ca_CNIC ca_ArmeSFo \
    ca_NIKHEF ca_CyGrid ca_PolishGrid ca_MARGI ca_PK-Grid-2007 ca_DCAROOT-G1 ca_BYGCA \
    ca_GermanGrid ca_LIPCA ca_IGCA2 ca_SlovakGrid ca_TRGrid ca_HKU ca_UNLPGrid ca_cilogon-silver \
    ca_DZeScience ca_ASGCCA-2007 ca_NCSA-slcs-2013 ca_MYIFAM ca_KEK ca_PKIUNAMgrid ca_PSC-Myproxy-CA \
    ca_QuoVadis-Grid-ICA-G2 ca_RomanianGRID ca_IRAN-GRID-GCG-G2 ca_UGRID-G2 ca_HKU-CA-2 ca_SiGNET-CA \
    ca_UNAMgrid-ca ca_NIIF-Root-CA-2 ca_AC-GRID-FR ca_AC-GRID-FR-Personnels ca_MREN-CA ca_INFN-CA-2015 \
    ca_seegrid-ca-2013 ca_AEGIS ca_RDIG ca_AC-GRID-FR-Services ca_HPCI ca_QuoVadis-Root-CA1 ca_MaGrid \
    ca_HellasGrid-CA-2016 ca_BG-ACAD-CA ca_CERN-LCG-IOTA-CA ca-policy-lcg ca-policy-egi-core
RUN yum clean all

# create bashs link to bash
RUN ln -s /bin/bash /usr/bin/bashs

# cd to workdir
WORKDIR $WDIR

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
RUN tar xfz go1.12.1.linux-amd64.tar.gz
RUN rm go1.12.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
# RUN mkdir -p $WDIR/gopath
# ENV GOPATH=$WDIR/gopath
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# get go dependencies which we'll use on all cmsweb nodes
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/buger/jsonparser
RUN go get github.com/Lusitaniae/apache_exporter
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common/log
RUN go get -d github.com/vkuznet/cmsweb-exporters

# make bin area in WDIR
RUN mkdir ${WDIR}/bin

# download and install grafana for prometheus
WORKDIR ${WDIR}
RUN curl -L -O https://grafanarel.s3.amazonaws.com/builds/grafana-2.5.0.linux-x64.tar.gz
RUN tar zxf grafana-2.5.0.linux-x64.tar.gz
RUN mv grafana-2.5.0 grafana
RUN rm grafana-2.5.0.linux-x64.tar.gz

# download node exporter
WORKDIR ${WDIR}
RUN curl -k -L -O https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz
RUN tar xfz node_exporter-0.15.2.linux-amd64.tar.gz
RUN cp node_exporter*/node_exporter $WDIR/bin

# build exporters
WORKDIR $GOPATH/src/github.com/vkuznet/cmsweb-exporters
RUN go build das2go_exporter.go
RUN cp das2go_exporter $WDIR/bin
RUN go build reqmgr_exporter.go
RUN cp reqmgr_exporter $WDIR/bin
RUN go build process_exporter.go
RUN cp process_exporter $WDIR/bin
RUN cp process_monitor.sh $WDIR/bin
RUN go build wmcore_exporter.go
RUN cp wmcore_exporter $WDIR/bin
ENV PATH="${GOPATH}/src/github.com/vkuznet/cmsweb-exporters:${GOPATH}/src/github.com/vkuznet/cmsweb-exporters/bin:${PATH}"

# setup final environment
ENV PATH="${WDIR}/bin:${GOPATH}/bin:${PATH}"

# start the setup
WORKDIR ${WDIR}
