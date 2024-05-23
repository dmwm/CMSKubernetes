FROM registry.cern.ch/cmsweb/oracle:21_5-stable as oracle
FROM registry.cern.ch/cmsweb/dmwm-base:pypi-20230525

# Install basic OS package dependencies
RUN apt-get update
RUN apt-get install -y libmariadb-dev-compat libmariadb-dev apache2-utils cron mariadb-server myproxy voms-clients rlwrap libaio1 && apt-get clean

# Install some debugging tools
RUN apt-get install -y hostname net-tools iputils-ping procps && apt-get clean

# Install recursive ps utility tool
RUN apt-get install -y pslist && apt-get clean

# copy oracle client:
COPY --from=oracle /usr/lib/oracle /usr/lib/oracle
ENV LD_LIBRARY_PATH=/usr/lib/oracle
ENV PATH=$PATH:/usr/lib/oracle
ENV PKG_CONFIG_PATH=/usr/lib/oracle
