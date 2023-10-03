FROM debian:stable-slim
RUN apt-get update && apt-get -y install curl
ENV TAG=debian92-x86_64-100.8.0
ENV WDIR=/data/mongo
WORKDIR $WDIR
RUN curl -ksLO https://fastdl.mongodb.org/tools/db/mongodb-database-tools-$TAG.tgz \
    && tar xfz mongodb-database-tools-$TAG.tgz \
    && rm mongodb-database-tools-$TAG.tgz \
    && mv mongodb-database-tools-$TAG/bin . \
    && rm -rf mongodb-database-tools-$TAG
ENV PATH="${WDIR}/bin:${PATH}"
WORKDIR $WDIR/bin
