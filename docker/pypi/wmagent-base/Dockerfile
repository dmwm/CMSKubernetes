FROM registry.cern.ch/cmsweb/oracle:21_5-stable as oracle
FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20250523-stable

# see https://docs.docker.com/build/building/best-practices/#apt-get
RUN apt-get update && apt-get install -y --no-install-recommends \
    # basic OS packages
    cron \
    mariadb-server libmariadb-dev-compat libmariadb-dev \
    myproxy voms-clients voms-clients-java \
    rlwrap libaio1 \
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
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
