FROM registry.cern.ch/cmsweb/pypi/alma-base:alma9-20240305
RUN dnf -y update && dnf -y install epel-release && dnf -y install wget 
RUN wget https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/f/fetch-crl-3.0.22-1.el9.noarch.rpm && \
    dnf -y install ./fetch-crl-3.0.22-1.el9.noarch.rpm && \
    rm -f fetch-crl-3.0.22-1.el9.noarch.rpm
COPY update-crl.sh /usr/local/bin/update-crl.sh
RUN chmod +x /usr/local/bin/update-crl.sh
CMD ["update-crl.sh"]
