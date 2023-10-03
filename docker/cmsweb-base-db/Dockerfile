FROM cern/cc7-base:20230928-1 as builder
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com

ENV WDIR=/data
ADD cernonly2.repo /etc/yum.repos.d/cernonlyw.repo
ADD slc7-cernonly.repo /etc/yum.repos.d/slc7-cernonly.repo
ADD epel.repo /etc/yum.repos.d/epel.repo

RUN yum install -y git-core make gcc golang sudo oracle-instantclient-tnsnames.ora \
            oracle-instantclient-devel oracle-instantclient-basic \
            && yum clean all && rm -rf /var/cache/yum

FROM cern/cc7-base:20230928-1
RUN yum install -y libaio && yum clean all && rm -rf /var/cache/yum
RUN mkdir -p /data
COPY --from=builder /usr/lib/oracle /usr/lib/oracle
COPY --from=builder /usr/include/oracle /usr/include/oracle
COPY --from=builder /etc/tnsnames.ora /etc
