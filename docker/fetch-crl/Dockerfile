FROM registry.cern.ch/cmsweb/pypi/alma-base:alma9-20240305
RUN dnf -y update && dnf -y install epel-release \
    dnf -y install fetch-crl ca-certificates

COPY update-crl.sh /usr/local/bin/update-crl.sh
RUN chmod +x /usr/local/bin/update-crl.sh

CMD ["update-crl.sh"]

