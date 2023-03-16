FROM golang:1.8-alpine AS build
RUN apk update && apk add ca-certificates && update-ca-certificates && apk add openssl
ARG SOPS_VERSION=v3.7.3
RUN set -ex \
    && wget https://github.com/mozilla/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux -O /usr/local/bin/sops \
    && chown root:root /usr/local/bin/sops \
    && chmod +x /usr/local/bin/sops \
    && sops --version

FROM gcr.io/distroless/static AS final
COPY --from=build /usr/local/bin/sops /usr/local/bin/sops
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ENTRYPOINT ["/usr/local/bin/sops"]
