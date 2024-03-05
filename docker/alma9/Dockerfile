FROM almalinux:latest
RUN yum update -y && \
    yum install -y curl libcurl vim python3-pycurl pip sudo less \
    && yum clean all && rm -rf /var/cache/yum