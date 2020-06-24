FROM cern/cc7-base:20200531-2.x86_64
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data/cmsweb
RUN mkdir -p $WDIR
ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo /etc/yum.repos.d/egi.repo
ADD http://linuxsoft.cern.ch/wlcg/wlcg-centos7.repo /etc/yum.repos.d/wlcg-centos7.repo
ADD hadoop.repo /etc/yum.repos.d/hadoop.repo
ADD epel.repo /etc/yum.repos.d/epel.repo
ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
ADD RPM-GPG-KEY-wlcg /etc/pki/rpm-gpg/RPM-GPG-KEY-wlcg
ADD logstash.repo /etc/yum.repos.d/logstash.repo

# add logstash GPG key
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

RUN yum update -y && yum clean all

# add necessary RPMs for cmsweb deployment
RUN yum install -y cern-get-certificate fetch-crl \
    git-core zip unzip which file bzip2 e2fsprogs e2fsprogs-libs compat-libstdc++-33 \
    CERN-CA-certs ca-certificates dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
    ca_EG-GRID ca_CERN-GridCA ca_CERN-LCG-IOTA-CA ca_CERN-Root-2 \
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
    libaio libaio-devel net-tools lsof bind-utils initscripts patch \
    voms-devel globus-gsi-credential-devel globus-gsi-cert-utils-devel \
    globus-common-devel globus-gsi-sysconfig-devel globus-gsi-callback-devel \
    oracle-instantclient-tnsnames.ora filebeat \
    HEP_OSlibs python-pip hadoop-bin hadoop-tools \
    spark spark-bin cern-hadoop-client cern-hadoop-xrootd-connector \
    && yum clean all && rm -rf /var/cache/yum

#RUN pip install --upgrade pip setuptools
RUN cp /usr/hdp/spark/kubernetes/dockerfiles/spark/entrypoint.sh /usr/bin/entrypoint.sh
RUN touch /etc/hadoop/conf/topology.table.file

# create bashs link to bash
RUN ln -s /bin/bash /usr/bin/bashs

# cd to workdir
WORKDIR $WDIR

# Install latest kubectl
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN mv kubectl /usr/bin
RUN chmod +x /usr/bin/kubectl

# download golang and install it
RUN curl -k -L -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
RUN tar xfz go1.12.1.linux-amd64.tar.gz
RUN rm go1.12.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# get go dependencies which we'll use on all cmsweb nodes
ENV GOPATH=$WDIR/gopath
RUN mkdir -p $GOPATH
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN go get github.com/dmwm/cmsauth
RUN go get github.com/vkuznet/x509proxy
RUN go get github.com/buger/jsonparser
RUN go get github.com/Lusitaniae/apache_exporter
RUN go get github.com/prometheus/client_golang/prometheus
RUN go get github.com/prometheus/common/log
RUN go get -d github.com/vkuznet/cmsweb-exporters
RUN go get github.com/shirou/gopsutil
RUN go get github.com/ryotarai/prometheus-query

# make bin area in WDIR
RUN mkdir ${WDIR}/bin

# download node exporter
WORKDIR ${WDIR}
RUN curl -k -L -O https://github.com/prometheus/node_exporter/releases/download/v0.15.2/node_exporter-0.15.2.linux-amd64.tar.gz
RUN tar xfz node_exporter-0.15.2.linux-amd64.tar.gz
RUN cp node_exporter*/node_exporter $WDIR/bin
RUN rm -r node_exporter-0.15.2.linux-amd64/
RUN rm -r node_exporter-0.15.2.linux-amd64.tar.gz

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
RUN go build cpy_exporter.go
RUN cp cpy_exporter $WDIR/bin
ENV PATH="${GOPATH}/src/github.com/vkuznet/cmsweb-exporters:${GOPATH}/src/github.com/vkuznet/cmsweb-exporters/bin:${PATH}"

# setup final environment
ENV PATH="${WDIR}/bin:${GOPATH}/bin:${PATH}"

# build mongo exporter
WORKDIR ${WDIR}
RUN curl -k -L -O "https://github.com/dcu/mongodb_exporter/archive/v1.0.0.tar.gz"
RUN tar xfz v1.0.0.tar.gz
RUN mkdir -p $GOPATH/src/github.com/dcu/
RUN cp -r mongodb_exporter-1.0.0 $GOPATH/src/github.com/dcu/mongodb_exporter
RUN rm -f v1.0.0.tar.gz
WORKDIR $GOPATH/src/github.com/dcu/mongodb_exporter
RUN go get github.com/Masterminds/glide
RUN make build
RUN cp mongodb_exporter $WDIR/bin

WORKDIR ${WDIR}
ADD print_hmac $WDIR/bin/print_hmac
ADD proxy.sh $WDIR/bin/proxy.sh
ADD hadoop-env.sh $WDIR/bin/hadoop-env.sh

# add fetch-crl to fetch all sertificates
RUN echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360" > /etc/cron.d/fetch-crl-docker

# start the setup
WORKDIR ${WDIR}
