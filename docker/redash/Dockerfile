FROM cmssw/cmsweb-base as cern
FROM redash/redash:8.0.0.b32245
COPY --from=cern /etc/grid-security /etc/grid-security
COPY --from=cern /usr/sbin/fetch-crl /usr/sbin/fetch-crl
COPY --from=cern /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt /etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
