FROM registry.cern.ch/cmsweb/oracle:23_9-go1.25-oci8-deb13-aio-stable as oracle
FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250905-stable

# see https://docs.docker.com/build/building/best-practices/#apt-get
RUN apt-get update && apt-get install -y --no-install-recommends \
    # basic OS packages
    cron \
    mariadb-server libmariadb-dev-compat libmariadb-dev \
    myproxy voms-clients voms-clients-java \
    rlwrap libaio1t64 \
    # required for cx_oracle
    build-essential \
    # required for yui 
    wget unzip \
    # debugging 
    hostname net-tools iputils-ping procps jq \
    # Install recursive ps utility tool
    pslist \
    s-nail \
    && rm -rf /var/lib/apt/lists/*

# copy oracle client:
COPY --from=oracle /usr/lib/oracle /usr/lib/oracle
RUN ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64.0.2 /usr/lib/x86_64-linux-gnu/libaio.so.1
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
