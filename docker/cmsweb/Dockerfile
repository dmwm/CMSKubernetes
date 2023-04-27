FROM registry.cern.ch/cmsweb/exporters:20210726-nonstatic as exporters-builder
RUN mkdir -p /data


FROM cern/cc7-base:20230426-1

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
RUN rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch && yum update -y && yum clean all

# add necessary RPMs for cmsweb deployment
RUN yum install -y cern-get-certificate fetch-crl \
    git-core zip unzip which file bzip2 e2fsprogs e2fsprogs-libs compat-libstdc++-33 \
    CERN-CA-certs ca-certificates dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
    ca_EG-GRID ca_CERN-GridCA ca_CERN-LCG-IOTA-CA ca_CERN-Root-2 \
    wlcg-voms-cms krb5-workstation krb5-libs pam_krb5 myproxy voms-clients-cpp voms-clients-java \
    sudo openssl openssl-devel openssl-libs openssh openssh-clients python-backports-ssl_match_hostname \
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

#RUN yum info CERN-CA-certs
#RUN update-ca-trust
#RUN pip install --upgrade pip setuptools
RUN cp /usr/hdp/spark/kubernetes/dockerfiles/spark/entrypoint.sh /usr/bin/entrypoint.sh && touch /etc/hadoop/conf/topology.table.file && ln -s /bin/bash /usr/bin/bashs

# cd to workdir
WORKDIR $WDIR

# Install latest kubectl
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && mv kubectl /usr/bin && chmod +x /usr/bin/kubectl && curl -k -L -O https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz && tar xfz go1.12.1.linux-amd64.tar.gz && rm go1.12.1.linux-amd64.tar.gz
ENV GOROOT=$WDIR/go
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"

# get go dependencies which we'll use on all cmsweb nodes
ENV PATH="${GOROOT}/bin:${WDIR}:${PATH}"
RUN mkdir -p $WDIR/bin

WORKDIR ${WDIR}


# setup final environment
ENV PATH="${WDIR}/bin:${PATH}"

# copy all exporters from exporters image

COPY --from=exporters-builder /data/cmsweb-ping ${WDIR}/bin/
COPY --from=exporters-builder /data/das2go_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/mongodb_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/cpy_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/http_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/node_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/process_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/reqmgr_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/wmcore_exporter ${WDIR}/bin/
COPY --from=exporters-builder /data/process_monitor.sh ${WDIR}/bin/


WORKDIR ${WDIR}
ADD print_hmac $WDIR/bin/print_hmac
ADD proxy.sh $WDIR/bin/proxy.sh
ADD hadoop-env.sh $WDIR/bin/hadoop-env.sh
ADD cmsweb-logs.sh $WDIR/bin/cmsweb-logs.sh
ADD eos-logs.sh $WDIR/bin/eos-logs.sh

# add fetch-crl to fetch all sertificates
RUN echo "32 */6 * * * root ! /usr/sbin/fetch-crl -q -r 360" > /etc/cron.d/fetch-crl-docker
# example how to run cmsweb-logs rsync
# RUN echo "*/10 * * * * /data/cmsweb/bin/cmsweb-logs.sh /etc/secrets/id_dsa_public /data/srv/logs cmsweb@vocms055:/build/k8s-logs" > /etc/cron.d/cmsweb-logs

# start the setup
WORKDIR ${WDIR}
