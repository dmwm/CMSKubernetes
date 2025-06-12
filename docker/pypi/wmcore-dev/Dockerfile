ARG PYTHON_VERSION=3.12
ARG IMAGE_VERSION=0.4.0

FROM --platform=linux/amd64 registry.cern.ch/cmsweb/gfal:alma9-py${PYTHON_VERSION}-1.13.0 as gfal2
FROM --platform=linux/amd64 registry.cern.ch/cmsweb/cmsweb-alma9-base:20240530

ARG PYTHON_VERSION

LABEL version=${IMAGE_VERSION}

ENV WDIR="/home/cmsbld"

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
RUN curl -O https://raw.githubusercontent.com/dmwm/WMCore/master/requirements.txt && \
    sed '/gfal2/d' /home/cmsbld/requirements.txt > /home/cmsbld/requirements-dev.txt && \
    sed -i '/nose~/d' /home/cmsbld/requirements-dev.txt

RUN uv pip install --no-cache-dir --upgrade pip setuptools wheel && \
    uv pip install --no-cache-dir -r /home/cmsbld/requirements-dev.txt && \
    uv pip install --no-cache-dir pynose~=1.5.4

# copy gfal2 and libboost
COPY --from=gfal2 /tmp/.venv/lib/python3.12/site-packages/gfal2.so $WDIR/.local/wmcore-venv/lib/python3.12/site-packages/gfal2.so
COPY --from=gfal2 /usr/local/lib/* /usr/local/lib/.

ADD entrypoint.sh /entrypoint.sh

ENV X509_HOST_CERT=/data/certs/servicecert.pem
ENV X509_HOST_KEY=/data/certs/servicekey.pem
ENV X509_USER_CERT=/data/certs/servicecert.pem
ENV X509_USER_KEY=/data/certs/servicekey.pem

ENTRYPOINT ["/entrypoint.sh"]

CMD ["sleep", "infinity"]
