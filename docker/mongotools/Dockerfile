FROM debian:stable-slim
RUN apt-get update && apt-get -y install curl
ENV WDIR=/data/mongo
WORKDIR $WDIR
# download mongodb tools
ENV MONGO_VER=debian92-x86_64-100.8.0
RUN curl -ksLO https://fastdl.mongodb.org/tools/db/mongodb-database-tools-$MONGO_VER.tgz \
    && tar xfz mongodb-database-tools-$MONGO_VER.tgz \
    && rm mongodb-database-tools-$MONGO_VER.tgz \
    && mv mongodb-database-tools-$MONGO_VER/bin . \
    && rm -rf mongodb-database-tools-$MONGO_VER
ENV PATH="${WDIR}/bin:${PATH}"
WORKDIR $WDIR/bin
# download sops tool
ENV SOPS_VER=v3.8.0
RUN curl -ksLO https://github.com/getsops/sops/releases/download/${SOPS_VER}/sops-${SOPS_VER}.linux.amd64
RUN mv sops-${SOPS_VER}.linux.amd64 sops && chmod +x sops
