FROM cern/cc7-base:20220601-1.x86_64
MAINTAINER Valentin Kuznetsov vkuznet@gmail.com
RUN yum install -y sudo krb5-workstation krb5-libs pam_krb5 && yum clean all && rm -rf /var/cache/yum
# Install latest kubectl
RUN curl -k -O -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && mv kubectl /usr/bin && chmod +x /usr/bin/kubectl
ENV WDIR=/data
WORKDIR ${WDIR}
ADD kerberos.sh $WDIR/kerberos.sh
CMD ["/data/kerberos.sh"]
