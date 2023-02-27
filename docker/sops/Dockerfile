FROM alpine:3.7
MAINTAINER Aroosha Pervaiz aroosha.pervaiz@cern.ch
ARG SOPS_VERSION=v3.7.2


RUN apk update && apk add --no-cache ca-certificates
RUN wget https://github.com/mozilla/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux -O /usr/local/bin/sops \
    && chmod 0755 /usr/local/bin/sops \
    && chown root:root /usr/local/bin/sops \
    && mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
ENTRYPOINT ["/usr/local/bin/sops"]
