ARG PYTHON_VERSION=3.12

FROM --platform=linux/amd64 registry.cern.ch/cmsweb/gfal:alma9-py${PYTHON_VERSION}-gfal-1.13.0-stable as gfal2
FROM --platform=linux/amd64 registry.cern.ch/cmsweb/dmwm-base:alma9-py3.12-20250728-stable

ARG PYTHON_VERSION
ARG WMCORE_TAG=2.4.1

LABEL version=${IMAGE_VERSION}

ENV WDIR="/home/cmsbld"

# Install EPEL repository (required for voms, fetch-crl and CA-related packages)
RUN dnf -y install epel-release && dnf -y upgrade && \
    dnf install -y http://linuxsoft.cern.ch/wlcg/el9/x86_64/wlcg-repo-1.0.0-1.el9.noarch.rpm && \
    dnf clean all

# Install cern repo
RUN dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --add-repo https://linuxsoft.cern.ch/cern/alma/9/devel/x86_64/os

ADD http://repository.egi.eu/sw/production/cas/1/current/repo-files/egi-trustanchors.repo /etc/yum.repos.d/egi.repo

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
        fetch-crl cern-get-certificate CERN-CA-certs ca-certificates \
        dummy-ca-certs ca-policy-lcg ca-policy-egi-core \
        ca_CERN-GridCA ca_CERN-Root-2 \
        voms-clients-cpp && \
    dnf clean all

# Create the working directory
RUN mkdir -p ${WDIR}/.local
WORKDIR $WDIR

# Install uv and make a venv based on the python version
ENV UV_PYTHON_INSTALL_DIR=$WDIR/.local/bin
RUN pip3 install uv && \
    uv python install ${PYTHON_VERSION}
ENV VIRTUAL_ENV="$WDIR/.local/wmcore-venv"
RUN uv venv -p ${PYTHON_VERSION} ${VIRTUAL_ENV}
ENV PATH="${VIRTUAL_ENV}/bin:$PATH"

# get requirements.txt and remove gfal2 to use RPM gfal2
RUN curl -O "https://raw.githubusercontent.com/dmwm/WMCore/$WMCORE_TAG/requirements.txt" && \
    sed -i '/gfal2/d' /home/cmsbld/requirements.txt

RUN uv pip install --no-cache-dir --upgrade pip setuptools wheel && \
    uv pip install --no-cache-dir -r /home/cmsbld/requirements.txt

# copy gfal2 and libboost
COPY --from=gfal2 /tmp/.venv/lib/python${PYTHON_VERSION}/site-packages/gfal2.so $WDIR/.local/wmcore-venv/lib/python${PYTHON_VERSION}/site-packages/gfal2.so
COPY --from=gfal2 /usr/local/lib/* /usr/local/lib/.

ADD entrypoint.sh /entrypoint.sh
ADD etc ${WDIR}/etc

ENV X509_HOST_CERT=/data/certs/servicecert.pem
ENV X509_HOST_KEY=/data/certs/servicekey.pem
ENV X509_USER_CERT=/data/certs/servicecert.pem
ENV X509_USER_KEY=/data/certs/servicekey.pem
ENV WMCORE_TAG=$WMCORE_TAG

ENTRYPOINT ["/entrypoint.sh"]

CMD ["sleep", "infinity"]
