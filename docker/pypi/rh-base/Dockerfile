FROM cern/cc7-base:latest
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN yum install -y curl lbcurl ibcurl-openssl-devel vim python3 pip python36-pycurl sudo less \
    && yum clean all && rm -rf /var/cache/yum
