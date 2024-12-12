FROM --platform=linux/amd64 registry.cern.ch/cmsweb/cmsweb-alma9-base:20240530

LABEL version="0.2.0"

# Install cern repo
RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --add-repo https://linuxsoft.cern.ch/cern/alma/9/devel/x86_64/os

# Install basic tools
RUN dnf upgrade -y && \
    dnf install -y \
        gcc \
        git \
        vim \
        libcurl-devel \
        python3 \
        python3-devel \
        python3-pip \
        mariadb-connector-c-devel \
        cmake \
        mariadb && \
    dnf clean all

# Install wlcg repo and gfal2
RUN dnf install -y http://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm && \
    dnf -y install \
        python3-gfal2 \
        python3-gfal2-util \
        gfal2-plugin-http \
        gfal2-plugin-dcap \
        gfal2-plugin-file \
        gfal2-plugin-srm \
        gfal2-plugin-xrootd \
        gfal2-plugin-gridftp \
        gfal2-plugin-sftp && \
    dnf clean all

# Tools for getting proxies
RUN dnf install -y \
        wlcg-voms-cms \
        voms-clients-cpp && \
    dnf clean all

# Create the working directory
RUN mkdir -p /home/cmsbld
WORKDIR /home/cmsbld

# get requirements.txt and remove gfal2 to use RPM gfal2
RUN curl -O https://raw.githubusercontent.com/dmwm/WMCore/master/requirements.txt && \
    sed '/gfal2/d' /home/cmsbld/requirements.txt > /home/cmsbld/requirements-dev.txt

# clone dmwm/WMCore repo and remove gfal2 to use RPM gfal2
# RUN git clone https://github.com/dmwm/WMCore && \
#     sed '/gfal2/d' /home/cmsbld/WMCore/requirements.txt > /home/cmsbld/WMCore/requirements-dev.txt

RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir --ignore-installed -r /home/cmsbld/requirements-dev.txt

ADD entrypoint.sh /entrypoint.sh

ENV X509_HOST_CERT=/data/certs/servicecert.pem
ENV X509_HOST_KEY=/data/certs/servicekey.pem
ENV X509_USER_CERT=/data/certs/servicecert.pem
ENV X509_USER_KEY=/data/certs/servicekey.pem

ENTRYPOINT ["/entrypoint.sh"]

CMD ["sleep", "infinity"]