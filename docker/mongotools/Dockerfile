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
# download age tool
ENV AGE_VER=v1.1.1
RUN curl -ksLO https://github.com/FiloSottile/age/releases/download/v1.1.1/age-${AGE_VER}-linux-amd64.tar.gz
RUN tar xfz age-${AGE_VER}-linux-amd64.tar.gz
RUN mv age agetools && mv agetools/age . && mv agetools/age-keygen . && rm -rf age-${AGE_VER}-linux-amd64.tar.gz agetools
# download mongo_manage.sh script
RUN curl -ksLO https://gist.githubusercontent.com/vkuznet/718e35f3782da467b1f86a82616b7ce4/raw/7f00f0d7dbf48e48d59d6cd706819ac69375e83e/mongo_manage.sh && chmod +x mongo_manage.sh
